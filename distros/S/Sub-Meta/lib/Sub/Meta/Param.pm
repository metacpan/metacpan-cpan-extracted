package Sub::Meta::Param;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.07";

use Scalar::Util ();

use overload
    fallback => 1,
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
    $args{type}     = delete $args{isa} if exists $args{isa};

    %args = (%DEFAULT, %args);

    return bless \%args => $class;
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

# alias
sub isa_() :method; # NOT isa
*isa_ = \&type;

sub set_isa($);
*set_isa = \&set_type;

sub is_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Param');

    return unless defined $self->name ? defined $other->name && $self->name eq $other->name
                                      : !defined $other->name;

    return unless defined $self->type ? defined $other->type && $self->type eq $other->type
                                      : !defined $other->type;

    return unless $self->optional eq $other->optional;

    return unless $self->named eq $other->named;

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;
    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Param')", $v, $v);

    push @src => defined $self->name ? sprintf("defined %s->name && '%s' eq %s->name", $v, "@{[$self->name]}", $v)
                                     : sprintf('!defined %s->name', $v);

    push @src => defined $self->type ? sprintf("defined %s->type && '%s' eq %s->type", $v, "@{[$self->type]}", $v)
                                     : sprintf('!defined %s->type', $v);

    push @src => sprintf("'%s' eq %s->optional", $self->optional, $v);

    push @src => sprintf("'%s' eq %s->named", $self->named, $v);

    return join "\n && ", @src;
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

=head2 ACCESSORS

=head3 name

variable name, e.g. C<$msg>, C<@list>.

=head3 set_name(Str $name)

Setter for C<name>.

=head3 type

Any type constraints, e.g. C<Str>.

=head3 set_type($type)

Setter for C<type>.

=head3 isa_

The alias of C<type>

=head3 set_isa($type)

The alias of C<set_type>

=head3 default

default value, e.g. C<"HELLO">, C<sub { ... }>

=head3 set_default($default)

Setter for C<default>.

=head3 coerce

A boolean value indicating whether to coerce. Default to false.

=head3 set_coerce($bool)

Setter for C<coerce>.

=head3 optional

A boolean value indicating whether to optional. Default to false.
This boolean is the opposite of C<required>.

=head3 set_optional($bool=true)

Setter for C<optional>.

=head3 required

A boolean value indicating whether to required. Default to true.
This boolean is the opposite of C<optional>.

=head3 set_required($bool=true)

Setter for C<required>.

=head3 named

A boolean value indicating whether to named arguments. Default to false.
This boolean is the opposite of C<positional>.

=head3 set_named($bool=true)

Setter for C<named>.

=head3 positional

A boolean value indicating whether to positional arguments. Default to true.
This boolean is the opposite of C<positional>.

=head3 set_positional($bool=true)

Setter for C<positional>.

=head2 OTHERS

=head3 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Param> object is same or not.
Specifically, check whether C<name>, C<type>, C<optional> and C<named> are equal.

=head3 is_same_interface_inlined($other_meta_inlined)

Returns inlined C<is_same_interface> string.

=head1 SEE ALSO

L<Sub::Meta::Parameters>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
