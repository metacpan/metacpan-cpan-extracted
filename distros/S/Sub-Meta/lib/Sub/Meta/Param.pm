package Sub::Meta::Param;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.10";

use Scalar::Util ();

use overload
    fallback => 1,
    eq       =>  \&is_same_interface,
;

my %DEFAULT = ( named => 0, optional => 0, invocant => 0 );

sub new {
    my ($class, @args) = @_;
    my $v = $args[0];
    my %args = @args == 1 ? ref $v && (ref $v eq 'HASH') ? %{$v}
                       : ( type => $v )
             : @args;

    $args{optional} = !delete $args{required} if exists $args{required};
    $args{named}    = !delete $args{positional} if exists $args{positional};
    $args{type}     = delete $args{isa} if exists $args{isa};

    %args = (%DEFAULT, %args);

    return bless \%args => $class;
}

sub name()       { my $self = shift; return $self->{name} }
sub type()       { my $self = shift; return $self->{type} }
sub default()    { my $self = shift; return $self->{default} } ## no critic (ProhibitBuiltinHomonyms)
sub coerce()     { my $self = shift; return $self->{coerce} }
sub optional()   { my $self = shift; return !!$self->{optional} }
sub required()   { my $self = shift; return !$self->{optional} }
sub named()      { my $self = shift; return !!$self->{named} }
sub positional() { my $self = shift; return !$self->{named} }
sub invocant()   { my $self = shift; return !!$self->{invocant} }

sub set_name      { my ($self, $v) = @_; $self->{name}     = $v; return $self }
sub set_type      { my ($self, $v) = @_; $self->{type}     = $v; return $self }
sub set_default   { my ($self, $v) = @_; $self->{default}  = $v; return $self }
sub set_coerce    { my ($self, $v) = @_; $self->{coerce}   = $v; return $self }
sub set_optional   { my ($self, $v) = @_; $self->{optional} = !!(defined $v ? $v : 1); return $self }
sub set_required   { my ($self, $v) = @_; $self->{optional} =  !(defined $v ? $v : 1); return $self }
sub set_named      { my ($self, $v) = @_; $self->{named}    = !!(defined $v ? $v : 1); return $self }
sub set_positional { my ($self, $v) = @_; $self->{named}    =  !(defined $v ? $v : 1); return $self }
sub set_invocant   { my ($self, $v) = @_; $self->{invocant} = !!(defined $v ? $v : 1); return $self }

# alias
sub isa_() :method; # NOT isa
*isa_ = \&type;

sub set_isa;
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

sub display {
    my $self = shift;

    my $s = '';
    $s .= $self->type if $self->type;
    $s .= ' ' if $s && $self->name;
    $s .= ':' if $self->named;
    $s .= $self->name if $self->name;
    return $s;
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

=head3 invocant

A boolean value indicating whether to be invocant. Default to false.

=head3 set_invocant($bool=true)

Setter for C<invocant>.

=head2 METHODS

=head3 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Param> object is same or not.
Specifically, check whether C<name>, C<type>, C<optional> and C<named> are equal.

=head3 is_same_interface_inlined($other_meta_inlined)

Returns inlined C<is_same_interface> string.

=head3 display

Returns the display of Sub::Meta::Param:

    use Sub::Meta::Param;
    use Types::Standard qw(Str);
    my $meta = Sub::Meta::Param->new(
        type => Str,
        name => '$message',
    );
    $meta->display;  # 'Str $message'

=head1 SEE ALSO

L<Sub::Meta::Parameters>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
