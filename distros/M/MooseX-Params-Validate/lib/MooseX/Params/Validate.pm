## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable)
package MooseX::Params::Validate;

use strict;
use warnings;

our $VERSION = '0.21';

use Carp 'confess';
use Devel::Caller 'caller_cv';
use Scalar::Util 'blessed', 'refaddr', 'reftype';

use Moose 2.1200 ();
use Moose::Util qw( throw_exception );
use Moose::Util::TypeConstraints
    qw( find_type_constraint class_type role_type );
use MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint;
use Params::Validate 1.15 ();

use Sub::Exporter -setup => {
    exports => [
        qw( validated_hash validated_list pos_validated_list validate validatep )
    ],
    groups => {
        default => [qw( validated_hash validated_list pos_validated_list )],
        deprecated => [qw( validate validatep )],
    },
};

my %CACHED_SPECS;

sub validated_hash {
    my ( $args, %spec ) = @_;

    my $cache_key = _cache_key( \%spec );

    my $allow_extra = delete $spec{MX_PARAMS_VALIDATE_ALLOW_EXTRA};

    if ( exists $CACHED_SPECS{$cache_key} ) {
        ( ref $CACHED_SPECS{$cache_key} eq 'HASH' )
            || confess
            "I was expecting a HASH-ref in the cached $cache_key parameter"
            . ' spec, you are doing something funky, stop it!';
        %spec = %{ $CACHED_SPECS{$cache_key} };
    }
    else {
        my $should_cache = delete $spec{MX_PARAMS_VALIDATE_NO_CACHE} ? 0 : 1;

        $spec{$_} = _convert_to_param_validate_spec(
            $spec{$_},
            qq{The '$_' parameter},
        ) foreach keys %spec;

        $CACHED_SPECS{$cache_key} = \%spec
            if $should_cache;
    }

    my $instance;
    $instance = shift @$args if blessed $args->[0];

    my %args
        = @$args == 1
        && ref $args->[0]
        && reftype( $args->[0] ) eq 'HASH' ? %{ $args->[0] } : @$args;

    $args{$_} = $spec{$_}{constraint}->coerce( $args{$_} )
        for grep { $spec{$_}{coerce} && exists $args{$_} } keys %spec;

    %args = Params::Validate::validate_with(
        params      => \%args,
        spec        => \%spec,
        allow_extra => $allow_extra,
        called      => _caller_name(),
    );

    return ( ( defined $instance ? $instance : () ), %args );
}

*validate = \&validated_hash;

sub validated_list {
    my ( $args, @spec ) = @_;

    my %spec = @spec;

    my $cache_key = _cache_key( \%spec );

    my $allow_extra = delete $spec{MX_PARAMS_VALIDATE_ALLOW_EXTRA};

    my @ordered_spec;
    if ( exists $CACHED_SPECS{$cache_key} ) {
        ( ref $CACHED_SPECS{$cache_key} eq 'ARRAY' )
            || confess
            "I was expecting a ARRAY-ref in the cached $cache_key parameter"
            . ' spec, you are doing something funky, stop it!';
        %spec         = %{ $CACHED_SPECS{$cache_key}->[0] };
        @ordered_spec = @{ $CACHED_SPECS{$cache_key}->[1] };
    }
    else {
        my $should_cache = delete $spec{MX_PARAMS_VALIDATE_NO_CACHE} ? 0 : 1;

        @ordered_spec = grep { exists $spec{$_} } @spec;

        $spec{$_} = _convert_to_param_validate_spec(
            $spec{$_},
            qq{The '$_' parameter},
        ) foreach keys %spec;

        $CACHED_SPECS{$cache_key} = [ \%spec, \@ordered_spec ]
            if $should_cache;
    }

    my $instance;
    $instance = shift @$args if blessed $args->[0];

    my %args
        = @$args == 1
        && ref $args->[0]
        && reftype( $args->[0] ) eq 'HASH' ? %{ $args->[0] } : @$args;

    $args{$_} = $spec{$_}{constraint}->coerce( $args{$_} )
        for grep { $spec{$_}{coerce} && exists $args{$_} } keys %spec;

    %args = Params::Validate::validate_with(
        params      => \%args,
        spec        => \%spec,
        allow_extra => $allow_extra,
        called      => _caller_name(),
    );

    return (
        ( defined $instance ? $instance : () ),
        @args{@ordered_spec}
    );
}

*validatep = \&validated_list;

sub pos_validated_list {
    my $args = shift;

    my @spec;
    push @spec, shift while ref $_[0];

    my %extra = @_;

    my $cache_key = _cache_key( \%extra );

    my $allow_extra = delete $extra{MX_PARAMS_VALIDATE_ALLOW_EXTRA};

    my @pv_spec;
    if ( exists $CACHED_SPECS{$cache_key} ) {
        ( ref $CACHED_SPECS{$cache_key} eq 'ARRAY' )
            || confess
            "I was expecting an ARRAY-ref in the cached $cache_key parameter"
            . ' spec, you are doing something funky, stop it!';
        @pv_spec = @{ $CACHED_SPECS{$cache_key} };
    }
    else {
        my $should_cache = exists $extra{MX_PARAMS_VALIDATE_NO_CACHE} ? 0 : 1;

        @pv_spec = map {
            _convert_to_param_validate_spec(
                $spec[$_],
                'Parameter #' . ( $_ + 1 )
                )
        } 0 .. $#spec;

        $CACHED_SPECS{$cache_key} = \@pv_spec
            if $should_cache;
    }

    my @args = @$args;

    $args[$_] = $pv_spec[$_]{constraint}->coerce( $args[$_] )
        for grep { $pv_spec[$_] && $pv_spec[$_]{coerce} } 0 .. $#args;

    @args = Params::Validate::validate_with(
        params      => \@args,
        spec        => \@pv_spec,
        allow_extra => $allow_extra,
        called      => _caller_name(),
    );

    return @args;
}

sub _cache_key {
    my $spec = shift;

    if ( exists $spec->{MX_PARAMS_VALIDATE_CACHE_KEY} ) {
        return delete $spec->{MX_PARAMS_VALIDATE_CACHE_KEY};
    }
    else {
        return refaddr( caller_cv(2) );
    }
}

sub _convert_to_param_validate_spec {
    my $spec = shift;
    my $id   = shift;

    my %pv_spec;

    $pv_spec{optional} = $spec->{optional}
        if exists $spec->{optional};

    $pv_spec{default} = $spec->{default}
        if exists $spec->{default};

    $pv_spec{coerce} = $spec->{coerce}
        if exists $spec->{coerce};

    $pv_spec{depends} = $spec->{depends}
        if exists $spec->{depends};

    my $constraint;
    if ( defined $spec->{isa} ) {
        $constraint = _is_tc( $spec->{isa} )
            || Moose::Util::TypeConstraints::find_or_parse_type_constraint(
            $spec->{isa} )
            || class_type( $spec->{isa} );
    }
    elsif ( defined $spec->{does} ) {
        $constraint
            = _is_tc( $spec->{does} )
            || find_type_constraint( $spec->{does} )
            || role_type( $spec->{does} );
    }

    $pv_spec{callbacks} = $spec->{callbacks}
        if exists $spec->{callbacks};

    if ($constraint) {
        $pv_spec{constraint} = $constraint;

        my $cb = sub {
            return 1 if $constraint->check( $_[0] );
            die
                MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint
                ->new(
                parameter => $id,
                type      => $constraint,
                value     => $_[0],
                );
        };

        $pv_spec{callbacks}
            { 'checking type constraint for ' . $constraint->name } = $cb;
    }

    delete $pv_spec{coerce}
        unless $pv_spec{constraint} && $pv_spec{constraint}->has_coercion;

    return \%pv_spec;
}

sub _is_tc {
    my $maybe_tc = shift;

    return $maybe_tc
        if defined $maybe_tc
        && blessed $maybe_tc
        && $maybe_tc->isa('Moose::Meta::TypeConstraint');
}

sub _caller_name {
    my $depth = shift || 0;

    return ( caller( 2 + $depth ) )[3];
}

no Moose::Util::TypeConstraints;

1;

# ABSTRACT: an extension of Params::Validate using Moose's types

__END__

=pod

=head1 NAME

MooseX::Params::Validate - an extension of Params::Validate using Moose's types

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  package Foo;
  use Moose;
  use MooseX::Params::Validate;

  sub foo {
      my ( $self, %params ) = validated_hash(
          \@_,
          bar => { isa => 'Str', default => 'Moose' },
      );
      return "Hooray for $params{bar}!";
  }

  sub bar {
      my $self = shift;
      my ( $foo, $baz, $gorch ) = validated_list(
          \@_,
          foo   => { isa => 'Foo' },
          baz   => { isa => 'ArrayRef | HashRef', optional => 1 },
          gorch => { isa => 'ArrayRef[Int]', optional => 1 }
      );
      [ $foo, $baz, $gorch ];
  }

=head1 DESCRIPTION

This module fills a gap in Moose by adding method parameter validation
to Moose. This is just one of many developing options, it should not
be considered the "official" one by any means though.

You might also want to explore C<MooseX::Method::Signatures> and
C<MooseX::Declare>.

=encoding UTF-8

=head1 CAVEATS

It is not possible to introspect the method parameter specs; they are
created as needed when the method is called and cached for subsequent
calls.

=head1 EXPORTS

=over 4

=item B<validated_hash( \@_, %parameter_spec )>

This behaves similarly to the standard Params::Validate C<validate>
function and returns the captured values in a HASH. The one exception
is where if it spots an instance in the C<@_>, then it will handle
it appropriately (unlike Params::Validate which forces you to shift
you C<$self> first).

The values in C<@_> can either be a set of name-value pairs or a single hash
reference.

The C<%parameter_spec> accepts the following options:

=over 4

=item I<isa>

The C<isa> option can be either; class name, Moose type constraint
name or an anon Moose type constraint.

=item I<does>

The C<does> option can be either; role name or an anon Moose type
constraint.

=item I<default>

This is the default value to be used if the value is not supplied.

=item I<optional>

As with Params::Validate, all options are considered required unless
otherwise specified. This option is passed directly to
Params::Validate.

=item I<coerce>

If this is true and the parameter has a type constraint which has
coercions, then the coercion will be called for this parameter. If the
type does have coercions, then this parameter is ignored.

=item I<depends>

Another parameter that this one depends on. See the L<Params::Validate>
documentation for more details.

=back

This function is also available under its old name, C<validate>.

=item B<validated_list( \@_, %parameter_spec )>

The C<%parameter_spec> accepts the same options as above, but returns
the parameters as positional values instead of a HASH. This is best
explained by example:

  sub foo {
      my ( $self, $foo, $bar ) = validated_list(
          \@_,
          foo => { isa => 'Foo' },
          bar => { isa => 'Bar' },
      );
      $foo->baz($bar);
  }

We capture the order in which you defined the parameters and then
return them as a list in the same order. If a param is marked optional
and not included, then it will be set to C<undef>.

The values in C<@_> can either be a set of name-value pairs or a single hash
reference.

Like C<validated_hash>, if it spots an object instance as the first
parameter of C<@_>, it will handle it appropriately, returning it as
the first argument.

This function is also available under its old name, C<validatep>.

=item B<pos_validated_list( \@_, $spec, $spec, ... )>

This function validates a list of positional parameters. Each C<$spec>
should validate one of the parameters in the list:

  sub foo {
      my $self = shift;
      my ( $foo, $bar ) = pos_validated_list(
          \@_,
          { isa => 'Foo' },
          { isa => 'Bar' },
      );

      ...
  }

Unlike the other functions, this function I<cannot> find C<$self> in
the argument list. Make sure to shift it off yourself before doing
validation.

The values in C<@_> must be a list of values. You cannot pass the values as an
array reference, because this cannot be distinguished from passing one value
which is itself an array reference.

If a parameter is marked as optional and is not present, it will
simply not be returned.

If you want to pass in any of the cache control parameters described
below, simply pass them after the list of parameter validation specs:

  sub foo {
      my $self = shift;
      my ( $foo, $bar ) = pos_validated_list(
          \@_,
          { isa => 'Foo' },
          { isa => 'Bar' },
          MX_PARAMS_VALIDATE_NO_CACHE => 1,
      );

      ...
  }

=back

=head1 EXCEPTION FOR FAILED VALIDATION

If a type constraint check for a parameter fails, then the error is thrown as
a L<MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint>
object. When stringified, this object will use the error message generated by
the type constraint that failed.

Other errors are simply percolated up from L<Params::Validate> as-is, and are
not turned into exception objects. This may change in the future (or more
likely, L<Params::Validate> may start throwing objects of its own).

=head1 ALLOWING EXTRA PARAMETERS

By default, any parameters not mentioned in the parameter spec cause this
module to throw an error. However, you can have this module simply ignore them
by setting C<MX_PARAMS_VALIDATE_ALLOW_EXTRA> to a true value when calling a
validation subroutine.

When calling C<validated_hash> or C<pos_validated_list> the extra parameters
are simply returned in the hash or list as appropriate. However, when you call
C<validated_list> the extra parameters will not be returned at all. You can
get them by looking at the original value of C<@_>.

=head1 EXPORTS

By default, this module exports the C<validated_hash>,
C<validated_list>, and C<pos_validated_list>.

If you would prefer to import the now deprecated functions C<validate>
and C<validatep> instead, you can use the C<:deprecated> tag to import
them.

=head1 IMPORTANT NOTE ON CACHING

When a validation subroutine is called the first time, the parameter spec is
prepared and cached to avoid unnecessary regeneration. It uses the fully
qualified name of the subroutine (package + subname) as the cache key.  In
99.999% of the use cases for this module, that will be the right thing to do.

However, I have (ab)used this module occasionally to handle dynamic
sets of parameters. In this special use case you can do a couple
things to better control the caching behavior.

=over 4

=item *

Passing in the C<MX_PARAMS_VALIDATE_NO_CACHE> flag in the parameter
spec this will prevent the parameter spec from being cached.

  sub foo {
      my ( $self, %params ) = validated_hash(
          \@_,
          foo                         => { isa => 'Foo' },
          MX_PARAMS_VALIDATE_NO_CACHE => 1,
      );

  }

=item *

Passing in C<MX_PARAMS_VALIDATE_CACHE_KEY> with a value to be used as
the cache key will bypass the normal cache key generation.

  sub foo {
      my ( $self, %params ) = validated_hash(
          \@_,
          foo                          => { isa => 'Foo' },
          MX_PARAMS_VALIDATE_CACHE_KEY => 'foo-42',
      );

  }

=back

=head1 MAINTAINER

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 BUGS

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=moosex-params-validate or via
email at bug-moosex-params-validate@rt.cpan.org.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords Dagfinn Ilmari Mannsåker Hans Staugaard Karen Etheridge

=over 4

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Hans Staugaard <h.staugaard@tweakker.com>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2015 by Stevan Little <stevan@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
