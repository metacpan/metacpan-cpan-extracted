package Sub::Meta::Param;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.11";

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

sub name()       { my $self = shift; return $self->{name} // '' }
sub type()       { my $self = shift; return $self->{type} // '' }
sub default()    { my $self = shift; return $self->{default} } ## no critic (ProhibitBuiltinHomonyms)
sub coerce()     { my $self = shift; return $self->{coerce} }
sub optional()   { my $self = shift; return !!$self->{optional} }
sub required()   { my $self = shift; return !$self->{optional} }
sub named()      { my $self = shift; return !!$self->{named} }
sub positional() { my $self = shift; return !$self->{named} }
sub invocant()   { my $self = shift; return !!$self->{invocant} }

sub has_name()    { my $self = shift; return defined $self->{name} }
sub has_type()    { my $self = shift; return defined $self->{type} }
sub has_default() { my $self = shift; return defined $self->{default} }
sub has_coerce()  { my $self = shift; return defined $self->{coerce} }

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

    if ($self->has_name) {
        return unless $self->name eq $other->name
    }
    else {
        return if $other->has_name
    }

    if ($self->has_type) {
        return unless $self->type eq $other->type
    }
    else {
        return if $other->has_type
    }

    return unless $self->optional eq $other->optional;

    return unless $self->named eq $other->named;

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;
    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Param')", $v, $v);

    push @src => $self->has_name ? sprintf("'%s' eq %s->name", $self->name, $v)
                                 : sprintf('!%s->has_name', $v);

    push @src => $self->has_type ? sprintf("'%s' eq %s->type", "@{[$self->type]}", $v)
                                 : sprintf('!%s->has_type', $v);

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

  method name() => Str

variable name, e.g. C<$msg>, C<@list>.

=head3 has_name

  method has_name() => Bool

Whether Sub::Meta::Param has name or not.

=head3 set_name($name)

  method set_name(Str $name) => $self

Setter for C<name>.

=head3 type

  method type() => Any

Any type constraints, e.g. C<Str>.

=head3 has_type

  method has_type() => Bool

Whether Sub::Meta::Param has type or not.

=head3 set_type($type)

  method set_type(Any $type) => $self

Setter for C<type>.

=head3 isa_

The alias of C<type>

=head3 set_isa($type)

The alias of C<set_type>

=head3 default

  method default() => Any

default value, e.g. C<"HELLO">, C<sub { ... }>

=head3 has_default

  method has_default() => Bool

Whether Sub::Meta::Param has default or not.

=head3 set_default($default)

  method set_default(Any $default) => $self

Setter for C<default>.

=head3 coerce

  method coerce() => Any

A boolean value indicating whether to coerce. Default to false.

=head3 has_coerce

  method has_coerce() => Bool

Whether Sub::Meta::Param has coerce or not.

=head3 set_coerce($coerce)

  method set_coerce(Any $coerce) => $self

Setter for C<coerce>.

=head3 optional

  method optional() => Bool

A boolean value indicating whether to optional. Default to false.
This boolean is the opposite of C<required>.

=head3 set_optional($bool=true)

  method set_optional(Bool $bool=true) => $self

Setter for C<optional>.

=head3 required

  method required() => Bool

A boolean value indicating whether to required. Default to true.
This boolean is the opposite of C<optional>.

=head3 set_required($bool=true)

  method set_required(Bool $bool=true) => $self

Setter for C<required>.

=head3 named

  method named() => Bool

A boolean value indicating whether to named arguments. Default to false.
This boolean is the opposite of C<positional>.

=head3 set_named($bool=true)

  method set_named(Bool $bool=true) => $self

Setter for C<named>.

=head3 positional

  method positional() => Bool

A boolean value indicating whether to positional arguments. Default to true.
This boolean is the opposite of C<positional>.

=head3 set_positional($bool=true)

  method set_positional(Bool $bool=true) => $self

Setter for C<positional>.

=head3 invocant

  method invocant() => Bool

A boolean value indicating whether to be invocant. Default to false.

=head3 set_invocant($bool=true)

  method set_invocant(Bool $bool=true) => $self

Setter for C<invocant>.

=head2 METHODS

=head3 is_same_interface($other_meta)

  method is_same_interface(InstanceOf[Sub::Meta::Param] $other_meta) => Bool

A boolean value indicating whether C<Sub::Meta::Param> object is same or not.
Specifically, check whether C<name>, C<type>, C<optional> and C<named> are equal.

=head3 is_same_interface_inlined($other_meta_inlined)

  method is_same_interface_inlined(InstanceOf[Sub::Meta::Param] $other_meta) => Str

Returns inlined C<is_same_interface> string.

=head3 display

  method display() => Str

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
