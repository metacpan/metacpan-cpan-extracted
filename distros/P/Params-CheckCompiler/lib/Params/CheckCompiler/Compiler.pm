package Params::CheckCompiler::Compiler;

use strict;
use warnings;

our $VERSION = '0.08';

use Eval::Closure;
use List::SomeUtils qw( first_index );
use Params::CheckCompiler::Exceptions;
use Scalar::Util qw( blessed looks_like_number reftype );
use Sub::Name qw( subname );
use overload ();

# I'd rather use Moo here but I want to make things relatively high on the
# CPAN river like DateTime use this distro, so reducing deps is important.
sub new {
    my $class = shift;
    my %p     = @_;

    my $self = bless \%p, $class;

    $self->{_source} = [];
    $self->{_env}    = {};

    return $self;
}

sub name      { $_[0]->{name} }
sub _has_name { exists $_[0]->{name} }

# I have no idea why critic thinks _caller isn't used.

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _caller { $_[0]->{caller} }
## use critic
sub _has_caller { exists $_[0]->{caller} }

sub params { $_[0]->{params} }

sub slurpy { $_[0]->{slurpy} }

sub _source { $_[0]->{_source} }

sub _env { $_[0]->{_env} }

sub subref {
    my $self = shift;

    $self->_compile;
    my $sub = eval_closure(
        source => 'sub { ' . ( join "\n", @{ $self->_source } ) . ' };',
        environment => $self->_env,
    );

    if ( $self->_has_name ) {
        my $caller = $self->_has_caller ? $self->_caller : caller(1);
        my $name = join '::', $caller, $self->name;
        subname( $name, $sub );
    }

    return $sub;
}

sub source {
    my $self = shift;

    $self->_compile;
    return (
        ( join "\n", @{ $self->_source } ),
        $self->_env,
    );
}

sub _compile {
    my $self = shift;

    if ( ref $self->params eq 'HASH' ) {
        $self->_compile_named_args_check;
    }
    elsif ( ref $self->params eq 'ARRAY' ) {
        $self->_compile_positional_args_check;
    }
}

sub _compile_named_args_check {
    my $self = shift;

    push @{ $self->_source }, $self->_set_named_args_hash;

    my $params = $self->params;

    for my $name ( sort keys %{$params} ) {
        my $spec = $params->{$name};
        $spec = { optional => !$spec } unless ref $spec;

        my $qname  = B::perlstring($name);
        my $access = "\$args{$qname}";

        $self->_add_check_for_required_named_param( $access, $name )
            unless $spec->{optional} || exists $spec->{default};

        $self->_add_default_assignment( $access, $name, $spec->{default} )
            if exists $spec->{default};

        $self->_add_type_check( $access, $name, $spec )
            if $spec->{type};
    }

    if ( $self->slurpy ) {
        $self->_add_check_for_extra_hash_param_types( $self->slurpy )
            if ref $self->slurpy;
    }
    else {
        $self->_add_check_for_extra_hash_params;
    }

    push @{ $self->_source }, 'return %args;';

    return;
}

sub _set_named_args_hash {
    my $self = shift;

    push @{ $self->_source }, <<'EOF';
my %args;
if ( @_ % 2 == 0 ) {
    %args = @_;
}
elsif ( @_ == 1 ) {
    if ( ref $_[0] ) {
        if ( Scalar::Util::blessed( $_[0] ) ) {
            if ( overload::Overloaded( $_[0] )
                && defined overload::Method( $_[0], '%{}' ) ) {

                %args = %{ $_[0] };
            }
            else {
                Params::CheckCompiler::Exception::BadArguments->throw(
                    message =>
                        'Expected a hash or hash reference but got a single object argument'
                );
            }
        }
        elsif ( Scalar::Util::reftype( $_[0] ) eq 'HASH' ) {
            %args = %{ $_[0] };
        }
        else {
            Params::CheckCompiler::Exception::BadArguments->throw(
                message =>
                    'Expected a hash or hash reference but got a single '
                    . ( Scalar::Util::reftype( $_[0] ) )
                    . ' reference argument',
            );
        }
    }
    else {
        Params::CheckCompiler::Exception::BadArguments->throw(
            message =>
                'Expected a hash or hash reference but got a single non-reference argument',
        );
    }
}
else {
    Params::CheckCompiler::Exception::BadArguments->throw(
        message =>
            'Expected a hash or hash reference but got an odd number of arguments',
    );
}
EOF

    return;
}

sub _add_check_for_required_named_param {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;

    my $qname = B::perlstring($name);
    push @{ $self->_source }, sprintf( <<'EOF', $access, ($qname) x 2 );
exists %s
    or Params::CheckCompiler::Exception::Named::Required->throw(
    message   => %s . ' is a required parameter',
    parameter => %s,
    );
EOF

    return;
}

sub _add_check_for_extra_hash_param_types {
    my $self = shift;
    my $type = shift;

    $self->_env->{'%known'} = { map { $_ => 1 } keys %{ $self->params } };

    # We need to set the name argument to something that won't conflict with
    # names someone would actually use for a parameter.
    my $check = join q{}, $self->_type_check(
        '$args{$key}',
        '__PCC extra parameters__',
        $type,
    );
    push @{ $self->_source }, sprintf( <<'EOF', $check );
for my $key ( grep { !$known{$_} } keys %%args ) {
    %s;
}
EOF

    return;
}

sub _add_check_for_extra_hash_params {
    my $self = shift;

    $self->_env->{'%known'} = { map { $_ => 1 } keys %{ $self->params } };
    push @{ $self->_source }, <<'EOF';
my @extra = grep { ! $known{$_} } keys %args;
if ( @extra ) {
    my $u = join ', ', sort @extra;
    Params::CheckCompiler::Exception::Named::Extra->throw(
        message    => "found extra parameters: [$u]",
        parameters => \@extra,
    );
}
EOF

    return;
}

sub _compile_positional_args_check {
    my $self = shift;

    my @specs = $self->_munge_and_check_positional_params;

    my $first_optional_idx = first_index { $_->{optional} } @specs;

    # If optional params start anywhere after the first parameter spec then we
    # must require at least one param. If there are no optional params then
    # they're all required.
    $self->_add_check_for_required_positional_params(
        $first_optional_idx == -1 ? ( scalar @specs ) : $first_optional_idx )
        if $first_optional_idx != 0;

    $self->_add_check_for_extra_positional_params( scalar @specs )
        unless $self->slurpy;

    for my $i ( 0 .. $#specs ) {
        my $spec = $specs[$i];

        my $name   = "Parameter $i";
        my $access = "\$_[$i]";

        $self->_add_default_assignment( $access, $name, $spec->{default} )
            if exists $spec->{default};

        $self->_add_type_check( $access, $name, $spec )
            if $spec->{type};
    }

    if ( ref $self->slurpy ) {
        $self->_add_check_for_extra_positional_param_types(
            scalar @specs,
            $self->slurpy,
        );
    }

    push @{ $self->_source }, 'return @_;';

    return;
}

sub _munge_and_check_positional_params {
    my $self = shift;

    my @specs;
    my $in_optional = 0;

    for my $spec ( @{ $self->params } ) {
        $spec = ref $spec ? $spec : { optional => !$spec };
        if ( $spec->{optional} ) {
            $in_optional = 1;
        }
        elsif ($in_optional) {
            die
                'Parameter list contains an optional parameter followed by a required parameter.';
        }

        push @specs, $spec;
    }

    return @specs;
}

sub _add_check_for_required_positional_params {
    my $self = shift;
    my $min  = shift;

    push @{ $self->_source }, sprintf( <<'EOF', ($min) x 3 );
if ( @_ < %d ) {
    my $got = scalar @_;
    my $got_n = @_ == 1 ? 'parameter' : 'parameters';
    Params::CheckCompiler::Exception::Positional::Required->throw(
        message => "got $got $got_n but expected at least %d",
        minimum => %d,
        got     => scalar @_,
    );
}
EOF

    return;
}

sub _add_check_for_extra_positional_param_types {
    my $self = shift;
    my $max  = shift;
    my $type = shift;

    # We need to set the name argument to something that won't conflict with
    # names someone would actually use for a parameter.
    my $check = join q{}, $self->_type_check(
        '$_[$i]',
        '__PCC extra parameters__',
        $type,
    );
    push @{ $self->_source }, sprintf( <<'EOF', $max, $max, $check );
if ( @_ > %d ) {
    for my $i ( %d .. $#_ ) {
        %s;
    }
}
EOF

    return;
}

sub _add_check_for_extra_positional_params {
    my $self = shift;
    my $max  = shift;

    push @{ $self->_source }, sprintf( <<'EOF', ($max) x 3 );
if ( @_ > %d ) {
    my $extra = @_ - %d;
    my $extra_n = $extra == 1 ? 'parameter' : 'parameters';
    Params::CheckCompiler::Exception::Positional::Extra->throw(
        message => "got $extra extra $extra_n",
        maximum => %d,
        got     => scalar @_,
    );
}
EOF

    return;
}

sub _add_default_assignment {
    my $self    = shift;
    my $access  = shift;
    my $name    = shift;
    my $default = shift;

    die 'Default must be either a plain scalar or a subroutine reference'
        if ref $default && reftype($default) ne 'CODE';

    my $qname = B::perlstring($name);
    push @{ $self->_source }, "unless ( exists \$args{$qname} ) {";

    if ( ref $default ) {
        push @{ $self->_source }, "$access = \$defaults{$qname}->();";
        $self->_env->{'%defaults'}{$name} = $default;
    }
    else {
        if ( defined $default ) {
            if ( looks_like_number($default) ) {
                push @{ $self->_source }, "$access = $default;";
            }
            else {
                push @{ $self->_source },
                    "$access = " . B::perlstring($default) . ';';
            }
        }
        else {
            push @{ $self->_source }, "$access = undef;";
        }
    }

    push @{ $self->_source }, '}';

    return;
}

sub _add_type_check {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;
    my $spec   = shift;

    my $type = $spec->{type};
    die "Passed a type that is not an object for $name: $type"
        unless blessed $type;

    push @{ $self->_source }, sprintf( 'if ( exists %s ) {', $access )
        if $spec->{optional};

    push @{ $self->_source },
        $self->_type_check( $access, $name, $spec->{type} );

    push @{ $self->_source }, '}'
        if $spec->{optional};

    return;
}

sub _type_check {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;
    my $type   = shift;

    # Specio
    return $type->can('can_inline_coercion_and_check')
        ? $self->_add_specio_check( $access, $name, $type )

        # Type::Tiny
        : $type->can('inline_assert')
        ? $self->_add_type_tiny_check( $access, $name, $type )

        # Moose
        : $type->can('can_be_inlined')
        ? $self->_add_moose_check( $access, $name, $type )
        : die 'Unknown type object ' . ref $type;
}

sub _add_type_tiny_check {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;
    my $type   = shift;

    my @source;
    if ( $type->has_coercion ) {
        my $coercion = $type->coercion;
        if ( $coercion->can_be_inlined ) {
            push @source,
                "$access = " . $coercion->inline_coercion($access) . ';';
        }
        else {
            $self->_env->{'%tt_coercions'}{$name}
                = $coercion->compiled_coercion;
            push @source,
                sprintf(
                '%s = $tt_coercions{%s}->( %s );',
                $access, $name, $access,
                );
        }
    }

    if ( $type->can_be_inlined ) {
        push @source,
            $type->inline_assert($access);
    }
    else {
        push @source,
            sprintf( '$types{%s}->assert_valid( %s );', $name, $access );
        $self->_env->{'%types'}{$name} = $type;
    }

    return @source;
}

sub _add_specio_check {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;
    my $type   = shift;

    my $qname = B::perlstring($name);

    my @source;

    if ( $type->can_inline_coercion_and_check ) {
        if ( $type->has_coercions ) {
            my ( $source, $env ) = $type->inline_coercion_and_check($access);
            push @source, sprintf( '%s = %s;', $access, $source );
            $self->_env->{$_} = $env->{$_} for keys %{$env};
        }
        else {
            my ( $source, $env ) = $type->inline_assert($access);
            push @source, $source . ';';
            $self->_env->{$_} = $env->{$_} for keys %{$env};
        }
    }
    else {
        my @coercions = $type->coercions;
        $self->_env->{'%specio_coercions'}{$name} = \@coercions;
        for my $i ( 0 .. $#coercions ) {
            my $c = $coercions[$i];
            if ( $c->can_be_inlined ) {
                push @source,
                    sprintf(
                    '%s = %s if %s;',
                    $access,
                    $c->inline_coercion($access),
                    $c->from->inline_check($access)
                    );
            }
            else {
                push @source,
                    sprintf(
                    '%s = $specio_coercions{%s}[%s]->coerce(%s) if $specio_coercions{%s}[%s]->from->value_is_valid(%s);',
                    $access,
                    $qname,
                    $i,
                    $access,
                    $qname,
                    $i,
                    $access
                    );
            }
        }

        push @source,
            sprintf( '$types{%s}->validate_or_die(%s);', $name, $access );
        $self->_env->{'%types'}{$name} = $type;
    }

    return @source;
}

sub _add_moose_check {
    my $self   = shift;
    my $access = shift;
    my $name   = shift;
    my $type   = shift;

    my @source;

    if ( $type->has_coercion ) {
        $self->_env->{'%moose_coercions'}{$name} = $type->coercion;
        push @source,
            sprintf(
            '%s = $moose_coercions{%s}->coerce( %s );',
            $access, $name, $access,
            );
    }

    $self->_env->{'%types'}{$name} = $type;

    my $code = <<'EOF';
if ( !%s ) {
    my $type = $types{%s};
    my $msg  = $type->get_message(%s);
    die
        Params::CheckCompiler::Exception::ValidationFailedForMooseTypeConstraint
        ->new(
        message   => $msg,
        parameter => 'The ' . %s . ' parameter',
        value     => %s,
        type      => $type,
        );
}
EOF

    my $check
        = $type->can_be_inlined
        ? $type->_inline_check($access)
        : sprintf( '$types{%s}->check( %s )', $name, $access );

    my $qname = B::perlstring($name);
    push @source, sprintf(
        $code,
        $check,
        $qname,
        $access,
        $qname,
        $access,
    );

    return @source;
}

1;

# ABSTRACT: Object that implements the check subroutine compilation

__END__

=pod

=encoding UTF-8

=head1 NAME

Params::CheckCompiler::Compiler - Object that implements the check subroutine compilation

=head1 VERSION

version 0.08

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Params-CheckCompiler>
(or L<bug-params-checkcompiler@rt.cpan.org|mailto:bug-params-checkcompiler@rt.cpan.org>).

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
