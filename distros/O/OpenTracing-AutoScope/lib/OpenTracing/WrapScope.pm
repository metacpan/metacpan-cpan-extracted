package OpenTracing::WrapScope;
our $VERSION = 'v0.107.1';
use strict;
use warnings;
use warnings::register;
use feature qw[ state ];
use B::Hooks::OP::Check::LeaveEval;
use Caller::Hide qw/hide_package/;
use Carp qw/croak/;
use List::Util qw/uniq/;
use OpenTracing::GlobalTracer;
use PerlX::Maybe;
use Scalar::Util qw/blessed/;
use Sub::Info qw/sub_info/;

hide_package(__PACKAGE__);

my %subs_to_install;
END {
    foreach my $sub (keys %subs_to_install) {
        next unless $subs_to_install{$sub}{warn_undetected};
        warnings::warn "OpenTracing::WrapScope couldn't find sub: $sub";
    }
}

sub _register_to_install {
    my ($signature, %args) = @_;
    my $warn_undetected = $args{warn_undetected};

    my ($sub) = _split_signature($signature);
    $subs_to_install{$sub} = {%args, signature => $signature };

    return;
}

sub _split_signature {
    my ($sig) = @_;
    return $sig unless $sig =~ s/\s*\((.*)\)\s*\z//;
    return ($sig, $1);    # just the name left over
}

# try to install any available subs whenever we get new code
B::Hooks::OP::Check::LeaveEval::register(sub {
    return unless %subs_to_install;

    foreach my $sub (keys %subs_to_install) {
        next unless defined &$sub;
        install_wrapped($subs_to_install{$sub}{signature});
        delete $subs_to_install{$sub};
    }
    return;
});

sub import {
    shift;    # __PACKAGE__
    my $target_package = caller;

    my $warn_undetected = 1;
    my ($use_env, @subs, @files);
    while (my (undef, $arg) = each @_) {
        if ($arg eq '-env') {
            $use_env = 1;
        }
        elsif ($arg eq '-file') {
            my (undef, $next) = each @_ or last;
            push @files, ref $next eq 'ARRAY' ? @$next : $next;
        }
        elsif ($arg eq '-quiet') {
            $warn_undetected = 0;
        }
        else {
            push @subs, _qualify_sub($arg, $target_package);
        }
    }
    if ($use_env and $ENV{OPENTRACING_WRAPSCOPE_FILE}) {
        push @files, split ':', $ENV{OPENTRACING_WRAPSCOPE_FILE};
    }
    push @subs, map { _load_sub_spec($_) } grep { -f } map { glob } uniq @files;

    foreach my $sub (@subs) {
        _register_to_install($sub, warn_undetected => $warn_undetected);
    }

    return;
}

sub install_wrapped {
    foreach my $sub (@_) {
        my ($sub_name, $args) = _split_signature($sub);
        my $full_sub = _qualify_sub($sub_name, scalar caller);

        if (not defined &$full_sub) {
            warnings::warn "Couldn't find sub: $full_sub";
            next;
        }

        my $wrapped = wrapped(\&$full_sub, $args);

        my ($class, $method) = split /(?:'|::)(?=\w+\z)/, $full_sub;
        if (_is_moose_class($class)) {   # Moose complains about replaced subs
            if ($class->meta->is_immutable) {
                warnings::warn "Can't wrap Moose method $sub from an immutable class";
                next;
            }
            $class->meta->add_method($method => $wrapped);
        }
        else {
            no strict 'refs';
            no warnings 'redefine';
            *$full_sub = $wrapped;
        }
    }
    return;
}

sub _is_moose_class {
    my ($class) = @_;
    my $meta = eval { $class->meta } or return;
    return blessed $meta && $meta->isa('Moose::Meta::Class');
}

sub wrapped {
    my ($coderef, $signature) = @_;
    my $info           = sub_info($coderef);
    my @tag_generators = _parse_signature($signature);

    return sub {
        my ($call_package, $call_filename, $call_line) = caller(0);
        my $call_sub = (caller(1))[3];
        
        my $tracer = OpenTracing::GlobalTracer->get_global_tracer; 
        my $scope = $tracer->start_active_span(
            "$info->{package}::$info->{name}",
            tags => {
                'source.subname' => $info->{name},
                'source.file'    => $info->{file},
                'source.line'    => $info->{start_line},
                'source.package' => $info->{package},
                maybe
                'caller.subname' => $call_sub,
                'caller.file'    => $call_filename,
                'caller.line'    => $call_line,
                'caller.package' => $call_package,
                map { $_->(@_) } @tag_generators,
            },
        );

        my $result;
        my $wantarray = wantarray;    # eval will have its own
        my $ok = eval {
            if (defined $wantarray) {
                $result = $wantarray ? [&$coderef] : &$coderef;
            }
            else {
                &$coderef;
            }
            1;
        };
        # TODO: message should go to logs but we don't have those yet
        $scope->get_span->add_tags(error => 1, message => "$@") unless $ok;
        $scope->close();

        die $@ unless $ok;
        return if not defined wantarray;
        return wantarray ? @$result : $result;
    };
}

sub _is_qualified { $_[0] =~ /\A\w+(?:'|::)/ }

sub _qualify_sub {
    my ($sub, $pkg) = @_;
    return $sub if _is_qualified($sub);
    $sub =~ s/\A(\w+)/${pkg}::$1/;
    return $sub;
}

sub _load_sub_spec {
    my ($filename) = @_;

    open my $fh_subs, '<', $filename or die "$filename: $!";

    my @subs;
    while (<$fh_subs>) {
        chomp;
        s/\s*#.*\Z//;    # remove comments
        next unless $_;

        croak "Unqualified subroutine: $_" unless _is_qualified($_);
        push @subs, $_;
    }
    close $fh_subs;

    return @subs;
}

sub wrap_from_file {
    my ($filename) = @_;
    install_wrapped( _load_sub_spec($filename) );
    return;
}


{
    my $gr = qr{
      (?(DEFINE)
        (?<COMMA>  \s* , \s* )
        (?<INT>    [0-9]+ )
        (?<RANGE>  (?&INT) \s* \.\. \s* (?&INT) )
        (?<AS_ARG> (?&RANGE) | (?&INT) )
        (?<HS_ARG> '[^']*' | "[^"]*" )
        (?<ARRAY_SLICE> \s* (?&AS_ARG) (?: (?&COMMA) (?&AS_ARG) )* \s* )
        (?<HASH_SLICE>  \s* (?&HS_ARG) (?: (?&COMMA) (?&HS_ARG) )* \s* )
      )
    }x;

    sub _parse_signature {
        my ($sig) = @_;
        return unless $sig;

        state $types = {
            '$'  => { greedy => 0, generator => \&_gen_scalar },
            '%'  => { greedy => 1, generator => \&_gen_hash },
            '@'  => { greedy => 1, generator => \&_gen_array },
            '\%' => { greedy => 0, generator => \&_gen_hash_ref },
            '\@' => { greedy => 0, generator => \&_gen_array_ref },
        };

        state $re = qr{
          (?: \A \s* | (?&COMMA) )
          (?:
              (?<type>     undef )
            | (?<type>        \$ ) (?<name> \w+ )
            | (?<type> (?:\\)? % ) (?<name> \w+ ) (?: \{ (?<slice> (?&HASH_SLICE) )  \} )?
            | (?<type> (?:\\)? @ ) (?<name> \w+ ) (?: \[ (?<slice> (?&ARRAY_SLICE) ) \] )?
          )
          $gr
        }x;

        my @tag_generators;
        my $arg_idx = 0;
        while ($sig =~ /\G$re/xcg) {
            my ($type, $name, $slice) = @+{qw[ type name slice ]};
            next if $type eq 'undef';    # hidden argument

            my $slice_ref = _parse_slice($type, $slice);
            my $type_ref  = $types->{$type} or die "No such type: $type";
            my $generator = $type_ref->{generator}->($name, $arg_idx, $slice_ref);
            push @tag_generators, $generator;

            last if $type_ref->{greedy};
        }
        continue {
            ++$arg_idx;
        }

        my $pos = pos($sig) // 0;
        if ($pos != length($sig)) {
            Carp::croak "Failed to parse signature:\n$sig\n", ' ' x $pos, '^';
        }

        return @tag_generators;
    }

    sub _parse_slice {
        my ($type, $slice) = @_;
        return unless $type and $slice;

        if ($type eq '@' or $type eq '\@') {
            my @args;
            while ($slice =~ /((?&AS_ARG)) $gr/gx) {
                my $arg = $1;
                push @args, $arg =~ /(\d+)\s*\.\.\s(\d+)/
                                 ? $1 .. $2    # expand ranges
                                 : $arg;
            }
            return \@args;
        }

        if ($type eq '%' or $type eq '\%') {
            my @args;
            while ($slice =~ /((?&HS_ARG)) $gr/gx) {
                push @args, $1 =~ s/\A['"]|['"]\z//gr;    # remove quotes
            }
            return \@args;
        }

        return;
    }
}

# undefs and references break OpenTracing::Interface type constraints
sub _str { defined $_[0] ? "$_[0]" : 'undef' }

sub _gen_scalar {
    my ($name, $arg_idx) = @_;
    return sub {
        return if $arg_idx > $#_;
        return ("arguments.$name" => _str($_[$arg_idx]));
    };
}

sub _gen_hash {
    my ($name, $arg_idx, $slice_ref) = @_;
    return sub {
        return if $arg_idx > $#_;

        no warnings 'misc';    # odd-sized list, etc. these are not our fault
        my %hash = @_[ $arg_idx .. $#_ ];
        return map {; "arguments.$name.$_" => _str($hash{$_}) } keys %hash unless $slice_ref;

        @$slice_ref = grep { exists $hash{$_} } @$slice_ref;
        my %sliced;
        @sliced{@$slice_ref} = @hash{@$slice_ref};
        return map { ; "arguments.$name.$_" => _str($sliced{$_}) } keys %sliced;
    };
}

sub _gen_array {
    my ($name, $arg_idx, $slice_ref) = @_;
    return sub {
        return if $arg_idx > $#_;

        my @args = @_[ $arg_idx .. $#_ ];
        return
            map {; "arguments.$name.$_" => _str($args[$_]) }
            $slice_ref ? grep { $_ <= $#args } @$slice_ref : keys @args;
    };
}

sub _gen_hash_ref {
    my ($name, $arg_idx, $slice_ref) = @_;
    return sub {
        return if $arg_idx > $#_;
        return if ref $_[$arg_idx] ne 'HASH';

        no warnings 'misc';    # odd-sized list, etc. these are not our fault
        my %hash = %{ $_[$arg_idx] };
        return map {; "arguments.$name.$_" => _str($hash{$_}) } keys %hash unless $slice_ref;

        @$slice_ref = grep { exists $hash{$_} } @$slice_ref;
        my %sliced;
        @sliced{@$slice_ref} = @hash{@$slice_ref};
        return map {; "arguments.$name.$_" => _str($sliced{$_}) } keys %sliced;
    };
}

sub _gen_array_ref {
    my ($name, $arg_idx, $slice_ref) = @_;
    return sub {
        return if $arg_idx > $#_;
        return if ref $_[$arg_idx] ne 'ARRAY';

        my @args = @{ $_[$arg_idx] };
        return
            map {; "arguments.$name.$_" => _str($args[$_]) }
            $slice_ref ? grep { $_ <= $#args } @$slice_ref : keys @args;
    };
}


1;
