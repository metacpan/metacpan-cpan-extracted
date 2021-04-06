package Spreadsheet::Compare::Config;

use Mojo::Base -base, -signatures;
use Spreadsheet::Compare::Common;
use Storable qw(dclone);
use Mojo::Template;
use Mojo::Util qw(monkey_patch);

my( $trace, $debug );
my %defaults;
my %sources;
my %protected;

#<<<
has from    => undef;
has plan    => sub { [] };
has globals => sub { {} }, ro => 1;
#>>>


sub import ( $class, $cfg = {}, %args ) {
    my $caller = caller;
    while ( my( $key, $value ) = each $cfg->%* ) {
        croak "duplicate definition for config option $key"
            if exists( $defaults{$key} )
            and $protected{$key};
        my $rt   = ref($value);
        my $wrap = ( not $rt or $rt eq 'CODE' ) ? $value : sub { $value };
        $sources{$caller}{$key} = $defaults{$key} = $wrap;
        $protected{$key} = 1 if $args{protected};
        Mojo::Base::attr( $caller, $key, $wrap ) if $args{make_attributes};
    }
    monkey_patch( $caller, 'config_defaults', sub { $sources{$caller} } );
    return;
}


sub init ($self) {
    $self->load( $self->{from} ) if $self->{from};
    $self->{current} = 0;
    return $self;
}


sub load ( $self, $src ) {
    $self->_make_plan( _load($src) );
    return $self;
}


sub next_test ($self) {
    state $idx = 0;
    my $test = $self->plan->[ $idx++ ];
    $idx = 0 unless $test;
    return $test;
}


sub _load ($src) {
    my $cfg;
    if ( my $rtype = ref($src) ) {
        if ( $rtype eq 'ARRAY' or $rtype eq 'HASH' ) {
            $cfg = dclone($src);
        }
        elsif ( $rtype eq 'GLOB' ) {
            local $/ = undef;
            $cfg = Load(<$src>);
        }
        else {
            croak "invalid reference type '$rtype' for configuration";
        }
    }
    else {
        INFO "loading configuration from '$src'";
        $cfg = $src =~ /\n/ ? Load($src) : LoadFile($src);
    }

    my $rcfg = ref($cfg);
    croak "invalid reference type '$rcfg' for configuration"
        unless $rcfg eq 'ARRAY' or $rcfg eq 'HASH';
    $cfg = [$cfg] if $rcfg eq 'HASH';

    return $cfg;
}


sub _make_plan ( $self, $cfg_main ) {

    my $globals = $self->_extract_globals($cfg_main);
    $globals->{title} = _get_title_from_filename( $self->from );
    $self->_expand_test($globals, $globals->{rootdir});

    my $plan = [];
    my %suite_globals;
    for my $cfg (@$cfg_main) {
        my $nbr = 1;
        $self->_expand_test($cfg);
        if ( $cfg->{suite} ) {
            croak "'suite' parameter in config has to be an array of filenames\n"
                unless ref( $cfg->{suite} ) eq 'ARRAY';
            my $root = $cfg->{rootdir} // $globals->{rootdir};
            for my $fn ( $cfg->{suite}->@* ) {
                $fn = "$root/$fn" if $root;
                DEBUG "reading suite file $fn";
                my $sub_cfg = _load($fn);

                my $suite_title = _get_title_from_filename($fn);
                $debug and DEBUG "suite title: $suite_title";
                $suite_globals{$fn} = $self->_extract_globals($sub_cfg);

                my $snbr = 1;
                for my $sub_entry (@$sub_cfg) {
                    $sub_entry->{$_} //= $cfg->{$_} for keys %$cfg;
                    $sub_entry->{_filename} = $fn;
                    $sub_entry->{suite_title} = $suite_title;
                    $sub_entry->{title} //= $suite_title . '_' . $snbr++;
                    push @$plan, $sub_entry;
                }
            }
        }
        else {
            $cfg->{suite_title} = _get_title_from_filename( $self->from );
            $cfg->{title} //= "Untitled_" . $nbr++;
            push @$plan, $cfg;
        }
    }

    $self->_expand_plan( $plan, $globals, \%suite_globals );
    INFO Dump(\%suite_globals);

    $self->plan($plan);
    $self->{__ro__globals} = $globals;

    return $self;
}


sub _extract_globals ( $self, $cfg, $fn = '' ) {
    $trace and TRACE '_extract_globals cfg:', Dump($cfg);
    my @idx = grep { ( $cfg->[$_]{title} // '' ) eq '__GLOBAL__' } 0 .. $#$cfg;
    croak "more than one __GLOBAL__ section in config $fn" if @idx > 1;
    my $globals = @idx ? splice( @$cfg, $idx[0], 1 ) : undef;
    delete $globals->{title};
    return $globals;
}


sub _expand_plan ( $self, $plan, $globals, $sglobals ) {
    my @t0 = localtime;
    local $ENV{SC_DATE}     = strftime( '%Y%m%d',       @t0 );
    local $ENV{SC_DATETIME} = strftime( '%Y%m%d%H%M%S', @t0 );
    for my $test (@$plan) {
        if ( $test->{_filename} and my $sg = $sglobals->{ $test->{_filename} } ) {
            delete $sg->{title};
            $test->{$_} //= $sg->{$_} for keys %$sg;
        }
        $test->{$_} //= $globals->{$_} for keys %$globals;
        $self->_expand_test($test);
    }
    $self->_expand_test($globals, $globals->{summary_filename} //= '');
    return $self;
}


sub _expand_test ( $self, $test, $element = undef ) {
    state $max_loop = 100;

    $element //= $test;
    my $reftype = ref($element);
    if ( $reftype eq 'ARRAY' ) {
        $self->_expand_test( $test, $_ ) for grep { defined } @$element;
    }
    elsif ( $reftype eq 'HASH' ) {
        $self->_expand_test( $test, $_ ) for grep { defined } values %$element;
    }
    elsif ( not $reftype ) {
        $_[2] //= '';
        my $loop_count = 0;
        while ( my( $sigil, $varname ) = $_[2] =~ /([\$\%])\{([^\}]+)\}/ ) {
            my $src = $sigil eq '$' ? \%ENV : $test;
            die "could not expand ${sigil}{$varname} in >>$test->{title}<<\n"
                unless exists $src->{$varname};
            my $rx = quotemeta("$sigil\{$varname\}");
            $_[2] =~ s/$rx/$src->{$varname}/g;
            LOGDIE "continuous loop while expanding variable $sigil\{$varname\} in '$element'"
                if ++$loop_count > $max_loop;
        }
    }

    return $self;
}


sub _get_title_from_filename ($filename) {
    $filename = $0 if not $filename or ref($filename);
    my $base = path($filename)->basename();
    $base =~ s/\.[^\.]+$//;
    return $base;
}


1;

=head1 NAME

Spreadsheet::Compare::Config - Build Configuration from File or Reference

=head1 SYNOPSIS

    use Spreadsheet::Compare::Config {
        array   => sub { [] },
        hash    => sub { {} },
        param   => undef,
    }, make_attributes => 1, protected => 1;

    my $cfg = Spreadsheet::Compare::Config->new(from => 'test.yml');

=head1 DESCRIPTION

This modules is used to  create attributes for the caller and keeps track of them,
so that it can check, if the same attribute is used in another module.

It is also used for taking comparison configuration and expanding it with the
defined default values and references. It creates an execution plan consisting
of an array with all expanded configurations.

=head1 ATTRIBUTES

=head2 from

If used directly in the constructor, will call L</load> directly with the attributes
value. Using it as a setter attribute at a later stage has no effect.

=head2 globals

A reference to a hash with the expanded values of the __GLOBAL__ configuration section.
Will be available after L</load> was called.

=head2 plan

A reference to an array of hashes containing the expanded parameters for comparisons.


=head1 METHODS

=head2 load($source)

Load a configuration. Source can be a reference to a hash with a single comparison definition,
a reference to an array with multiple definitions or a filename/filehandle of a YAML
configuration file containing either.

=head2 next_test

Return the next test configuration (a reference to a hash).
Will return undef once if the end is reached and restart at index 0 afterwards.

=cut
