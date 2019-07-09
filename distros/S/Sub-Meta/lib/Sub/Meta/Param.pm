package Sub::Meta::Param;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.04";

use overload
    fallback => 1,
    '""'     => sub { $_[0]->name || '' },
    eq       =>  \&is_same_interface,
;

my %DEFAULT = ( named => 0, optional => 0 );

sub new {
    my $class = shift;
    my %args = @_ == 1 ? ref $_[0] && (ref $_[0] eq 'HASH') ? %{$_[0]}
                       : ( type => $_[0] )
             : @_;

    $args{optional} = !delete $args{required} if exists $args{required};
    $args{named}    = !delete $args{positional} if exists $args{positional};

    %args = (%DEFAULT, %args);

    bless \%args => $class;
}

sub name()       { $_[0]{name} }
sub type()       { $_[0]{type} }
sub default()    { $_[0]{default} }
sub coerce()     { $_[0]{coerce} }
sub optional()   { !!$_[0]{optional} }
sub required()   { !$_[0]{optional} }
sub named()      { !!$_[0]{named} }
sub positional() { !$_[0]{named} }

sub set_name($)      { $_[0]{name}     = $_[1];   $_[0] }
sub set_type($)      { $_[0]{type}     = $_[1];   $_[0] }
sub set_default($)   { $_[0]{default}  = $_[1];   $_[0] }
sub set_coerce($)    { $_[0]{coerce}   = $_[1];   $_[0] }
sub set_optional($;)   { $_[0]{optional} = !!(defined $_[1] ? $_[1] : 1); $_[0] }
sub set_required($;)   { $_[0]{optional} =  !(defined $_[1] ? $_[1] : 1); $_[0] }
sub set_named($;)      { $_[0]{named}    = !!(defined $_[1] ? $_[1] : 1); $_[0] }
sub set_positional($;) { $_[0]{named}    =  !(defined $_[1] ? $_[1] : 1); $_[0] }

sub is_same_interface {
    my ($self, $other) = @_;

    if (defined $self->name) {
        return unless $self->name eq $other->name;
    }
    else {
        return if defined $other->name;
    }

    if (defined $self->type) {
        return unless $self->type eq $other->type;
    }
    else {
        return if defined $other->type;
    }

    return unless $self->optional eq $other->optional;
    return unless $self->named eq $other->named;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Param - element of Sub::Meta::Parameters

=head1 SYNOPSIS

    use Sub::Meta::Param

    # specify all parameters
    my $param = Sub::Meta::Param->new(
        type     => 'Str',
        name     => '$msg',
        default  => 'world',
        coerce   => 0,
        optional => 0, # default
        named    => 0, # default
    );

    $param->type; # => 'Str'

    # omit parameters
    my $param = Sub::Meta::Param->new('Str');
    $param->type; # => 'Str'
    $param->positional; # => !!1
    $param->required;   # => !!1

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta::Param>.

    use Types::Standard -types;

    Sub::Meta::Param->new({
        type       => ArrayRef[Int],
        required   => 1,
        positional => 1,
    })

=head2 name

variable name, e.g. C<$msg>, C<@list>.

=head2 set_name(Str $name)

Setter for C<name>.

=head2 type

Any type constraints, e.g. C<Str>.

=head2 set_type($type)

Setter for C<type>.

=head2 default

default value, e.g. C<"HELLO">, C<sub { ... }>

=head2 set_default($default)

Setter for C<default>.

=head2 coerce

A boolean value indicating whether to coerce. Default to false.

=head2 set_coerce($bool)

Setter for C<coerce>.

=head2 optional

A boolean value indicating whether to optional. Default to false.
This boolean is the opposite of C<required>.

=head2 set_optional($bool=true)

Setter for C<optional>.

=head2 required

A boolean value indicating whether to required. Default to true.
This boolean is the opposite of C<optional>.

=head2 set_required($bool=true)

Setter for C<required>.

=head2 named

A boolean value indicating whether to named arguments. Default to false.
This boolean is the opposite of C<positional>.

=head2 set_named($bool=true)

Setter for C<named>.

=head2 positional

A boolean value indicating whether to positional arguments. Default to true.
This boolean is the opposite of C<positional>.

=head2 set_positional($bool=true)

Setter for C<positional>.

=head2 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Param> object is same or not.
Specifically, check whether C<name>, C<type>, C<optional> and C<named> are equal.

=head1 SEE ALSO

L<Sub::Meta::Parameters>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
