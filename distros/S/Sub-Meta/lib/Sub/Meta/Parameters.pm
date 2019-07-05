package Sub::Meta::Parameters;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.03";

use Carp ();
use Scalar::Util ();

use Sub::Meta::Param;

sub _croak { require Carp; Carp::croak(@_) }

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    _croak 'parameters reqruires args' unless exists $args{args};

    $args{nshift} = 0 unless exists $args{nshift};
    $args{slurpy} = 0 unless exists $args{slurpy};
    $args{args}   = $class->_normalize_args($args{args});

    my $self = bless \%args => $class;
    $self->_assert_nshift;
    return $self;
}

sub nshift()   { $_[0]{nshift} }
sub slurpy()   { !!$_[0]{slurpy} }
sub args()     { $_[0]{args} }

sub set_nshift($) { $_[0]{nshift} = $_[1]; $_[0]->_assert_nshift; $_[0] }
sub set_slurpy() { $_[0]{slurpy} = !!(defined $_[1] ? $_[1] : 1); $_[0] }

sub set_args {
    my $self = shift;
    $self->{args} = $self->_normalize_args(@_);
    return $self;
}

sub _normalize_args {
    my $self = shift;
    my @args = @_ == 1 && ref $_[0] && (ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_;
    [ map { Scalar::Util::blessed($_) ? $_ : Sub::Meta::Param->new($_) } @args ]
}

sub _assert_nshift {
    my $self = shift;
    if (@{$self->_all_positional_required} < $self->nshift) {
        _croak 'required positional parameters need more than nshift';
    }
}

sub _all_positional_required() {
    [ grep { $_->positional && $_->required } @{$_[0]->args} ];
}

sub positional() {
    my $self = shift;
    my @p = grep { $_->positional } @{$self->args};
    splice @p, 0, $self->nshift;
    [ @p ];
}

sub positional_required() {
    my $self = shift;
    my @p = @{$self->_all_positional_required};
    splice @p, 0, $self->nshift;
    [ @p ];
}

sub positional_optional() { [ grep { $_->positional && $_->optional } @{$_[0]->args} ] }

sub named()               { [ grep { $_->named                      } @{$_[0]->args} ] }
sub named_required()      { [ grep { $_->named && $_->required      } @{$_[0]->args} ] }
sub named_optional()      { [ grep { $_->named && $_->optional      } @{$_[0]->args} ] }


sub invocant() {
    my $self = shift;
    my $nshift = $self->nshift;
    return undef if $nshift == 0;
    return $self->_all_positional_required->[0] if $nshift == 1;
    _croak "Can't return a single invocant; this function has $nshift";
}

sub invocants() {
    my $self = shift;
    my @p = @{$self->_all_positional_required};
    splice @p, $self->nshift;
    [ @p ]
}

sub args_min() {
    my $self = shift;
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->named_required} * 2;
    $r
}

sub args_max() {
    my $self = shift;
    return 0 + 'Inf' if $self->slurpy || @{$self->named};
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->positional_optional};
    $r
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Parameters - meta information about parameters

=head1 SYNOPSIS

    use Sub::Meta::Parameters;

    my $p1 = Sub::Meta::Parameters->new(
        args => ['Str']
    );
    $p1->invocant;            # => undef;
    $p1->invocants;           # => [];
    $p1->positional;          # => [Sub::Meta::Param->new('Str')]
    $p1->positional_required; # => [Sub::Meta::Param->new('Str')]
    $p1->positional_optional; # => []
    $p1->named;               # => []
    $p1->named_required;      # => []
    $p1->named_optional;      # => []
    $p1->nshift;              # => 0
    $p1->slurpy;              # => 0
    $p1->args_min;            # => 1
    $p1->args_max;            # => 1


    my $x = Sub::Meta::Param->new({ type => 'Int', name => '$x', named => 1 });
    my $y = Sub::Meta::Param->new({ type => 'Int', name => '$y', named => 1 });

    my $p2 = Sub::Meta::Parameters->new(
        nshift => 1,
        args => [
            'ClassName', $x, $y
        ]
    );

    $p2->invocant;            # => Sub::Meta::Param->new('ClassName');
    $p2->invocants;           # => [Sub::Meta::Param->new('ClassName')];
    $p2->positional;          # => []
    $p2->positional_required; # => []
    $p2->positional_optional; # => []
    $p2->named;               # => [$x, $y]
    $p2->named_required;      # => [$x, $y]
    $p2->named_optional;      # => []
    $p2->nshift;              # => 1
    $p2->slurpy;              # => 0
    $p2->args_min;            # => 5
    $p2->args_max;            # => 0+'Inf'

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta::Parameters>.

    my $p = Sub::Meta::Parameters->new(
        args   => ['Str'], # required. arguments
        nshift => 0,       # optional. number of shift arguments
        slurpy => 0,       # optional. whether get all rest arguments
    );

=head2 args

Subroutine arguments arrayref.

=head2 set_args(LIST), set_args(ArrayRef)

Setter for subroutine arguments.
An element can be an argument of C<Sub::Meta::Param> or any object which has C<positional>,C<named>,C<required> and C<optional> methods.

=head2 nshift

Number of shift arguments.

=head2 set_nshift($nshift)

Setter for nshift.
For example, it is assumed that 1 is specified in the case of methods, and 0 is specified in the case of normal functions.

=head2 slurpy

A boolean whether get all rest arguments.

=head2 set_slurpy($bool)

Setter for slurpy.

=head2 positional

Returns an arrayref of parameter objects for the positional arguments.

=head2 positional_required

Returns an arrayref of parameter objects for the required positional arguments.

=head2 positional_optional

Returns an arrayref of parameter objects for the optional positional arguments.

=head2 named

Returns an arrayref of parameter objects for the named arguments.

=head2 named_required

Returns an arrayref of parameter objects for the required named arguments.

=head2 named_optional

Returns an arrayref of parameter objects for the optional named arguments.

=head2 invocant

First element of invocants.

=head2 invocants

Returns an arrayref of parameter objects for the variables into which initial arguments are shifted automatically. This will usually return () for normal functions and ('$self') for methods.

=head2 args_min

Returns the minimum number of required arguments.

This is computed as follows:
  Invocants and required positional parameters count 1 each.
  Optional parameters don't count.
  Required named parameters count 2 each (key + value).
  Slurpy parameters don't count either because they accept empty lists.

=head2 args_max

Returns the maximum number of arguments.

This is computed as follows:
  If there are any named or slurpy parameters, the result is Inf.
  Otherwise the result is the number of all invocants and positional parameters.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

