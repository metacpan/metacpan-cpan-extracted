package Pointer;
use Spiffy 0.23 -Base;
use Carp;
use overload qw("" stringify + add - subtract);
use Config;
our $VERSION = '0.11';
our @EXPORT = qw(pointer);

use constant POINTER => 'L!'; # XXX not totally portable

const type => 'void';
const sizeof => 1;
const pack_template => 'b';
field address => undef;

sub pointer() {
    __PACKAGE__->new(@_);
}

my $type_map = {};
sub get_class {
    my $type = shift;
    return $type_map->{$type} if defined $type_map->{$type};
    $type_map = {};
    for my $class (keys %INC) {
        $class =~ s|/|::|g;
        $class =~ s/\.pm$//;
        next unless $class->isa('Pointer');
        my $class_type = $class->type;
        if (not $type_map->{$class_type} or
            $class->isa($type_map->{$class_type})
           ) {
            $type_map->{$class_type} = $class;
        }
    }
    return $type_map->{$type} if defined $type_map->{$type};
    croak "No class to handle pointer type '$type'";
}

sub new {
    my ($args, @values) = $self->parse_arguments(@_);
    my ($type, $address) = @values;
    $type ||= 'void';
    my $real_class = $self->get_class($type);    
    $self = bless {}, $real_class;
    $self->address($address);
    return $self;
}

sub stringify {
    overload::StrVal($self);
}

sub add {
    my $number = shift;
    croak "Invalid pointer addition" if ref $number;
    my $result = Pointer->new($self->type);
    $result->address($self->address + $number * $self->sizeof);
    return $result;
}

sub subtract {
    my ($number, $reverse) = @_;
    croak "Invalid pointer subtraction" if $reverse or ref $number;
    my $result = Pointer->new($self->type);
    $result->address($self->address - $number * $self->sizeof);
    return $result;
}

sub ptrsize {
    $Config::Config{ptrsize};
}

sub to {
    my $address = shift;
    $self->address($address);
    return $self;
} 

sub of_scalar {
    $self->address(hex $self->scalar_id($_[0]));
    return $self;
} 

sub hex_address {
    my $address = $self->assert_address;
    sprintf '0x%x', $address;
}

sub assert_pointer {
    return pack(POINTER, $self->assert_address);
}

sub assert_address {
    my $address = $self->address;
    croak "Undefined pointer"
      unless defined $address;
    return $address;
}

sub reverse_bytes {
    local $_ = shift;
    join '', reverse split;
}

sub get {
    my $count = shift || 1;
    my $length = $count * $self->sizeof;
    unpack $self->pack_template . $count, $self->get_raw($length);
}

sub get_raw {
    my $length = shift || 1;
    unpack "P$length", $self->assert_pointer;
}

sub get_hex {
    my $count = shift || 1;
    my $sizeof = $self->sizeof;
    my $length = $count * $sizeof;
    my @values = map {
        unpack 'H' . $sizeof * 2, $_
    } $self->get_raw($length) =~ /(.{$sizeof})/g;
    return wantarray ? @values : $values[0];
}

sub get_pointer {
    my $pointer = Pointer->new(@_);
    $pointer->address(unpack POINTER, $self->get_raw($self->ptrsize));
    return $pointer;
}

sub get_string {
    unpack 'p*', $self->assert_pointer;
}

sub scalar_id {
    return
      overload::StrVal(\ $_[0]) =~ qr{^(?:.*\=)?[^=]*\(([^\(]*)\)$}o
      ? $1
      : croak "Can't find id of scalar";
}

__END__
#==============================================================================#
package Pointer::int;
use strict;
Pointer->import('-base');

field sizeof => $Config::Config{intsize};
field type => 'int';
field pack_template => 'i!';

1;

__END__

=head1 NAME

Pointer - Object Oriented Memory Pointers in Pure Perl

=head1 SYNOPSIS

 use Pointer;
 use Pointer::int;
 use Pointer::sv;

 # Hello, world the hard way
 print pointer->of_scalar("Hello, world")->get_pointer->get_pointer->get_string;

 # Test to see if a scalar is a string
 print "It's a string!"
   if pointer('sv')->of_scalar('12345')->sv_flags & SVf_POK;

 # Hex dump of the first 3 words of the SV for $/
 print "> $_\n" for pointer('int')->of_scalar($/)->get_hex(3);

 # Print 5 integers 10 integers away from the address of $$
 print((pointer('int')->of_scalar($$) + 10)->get(5));

=head1 DESCRIPTION

This module allows you to create Perl objects that emulate C pointers.
You can use them to read and explore the memory of your Perl process.

Pointer.pm (and every subclass) exports a function called C<pointer>
that returns a new pointer object. Each object has a type like (void,
int, long, sv). Support for each pointer type is written as a subclass
of Pointer.pm. Pointer.pm itself is for type C<void>. To create a
pointer to a long integer, do:

    use Pointer::long;
    my $p = pointer('long');

Your new pointer is not pointing to anything yet. One way to put an
address into the pointer is directly, like this:

    $p->to(0x123456);

Another way is to point it at an existing scalar like this:

    $p->of_scalar($foo);

Both of these methods return the pointer so that you can chain other
methods onto them:

    my $int = $p->of_scalar($foo)->get;

The C<get> method returns whatever the pointer points to. Since C<$p> is
an integer pointer, this call returns an integer. The C<get> method
takes an optional number as an argument, which indicates the number of
values to get.

Pointer pointers honor pointer arithmetic. If you add or subtract a
number to a pointer, the result is another pointer. As in C pointer
arithmetic, the number of bytes added to the address depends on the size
of the type represented by the pointer.

    my $p1 = pointer('long')->of_scalar($foo);
    my $p2 = $p1 - 5;

is the same as:

    my $p1 = pointer('long')->of_scalar($foo);
    my $p2 = pointer('long')->address($p1->address - 5 * $p1->sizeof);

=head1 METHODS

The following methods are available for all pointers:

=over 4

=item * to()

Sets the address of a pointer to a specific integer. Returns the pointer
object for chaining calls.

=item * of_scalar()

Sets the address of a pointer to the address a Perl scalar or SV.
Returns the pointer object for chaining calls.

=item * address()

Returns the memory address of the pointer as an integer.

=item * hex_address()

Returns the address as a hexadecimal string.

=item * type()

Returns the type of the pointer.

=item * sizeof()

Returns the size (in bytes) of whatever type of data is pointed to.

=item * get()

Get the item(s) pointed to by the pointer. This function takes a numeric
argument indicating how many items you want to retrieve. The function
returns a list of the items requested.

=item * get_hex()

Similar to C<get>, but returns the items in hexadeciaml.

=item * get_string()

Returns the null terminated string pointed to by the pointer.

=item * get_pointer()

If your pointer points to a pointer address, this call will take the
pointer address, and return a new pointer object that contains it.
You can pass in the type of the new pointer. The default type is a
void pointer.

=item * get_raw()

Returns the raw byte content pointed to by the pointer. You will need to
unpack the raw data yourself. Takes an argument indicating how many
bytes to return.

=back

=head1 SUBCLASSING

Pointer.pm was made to be subclassed. Every type of pointer is a
subclass. See the modules: Pointer::int, Pointer::long and Pointer::sv
for examples.

=head1 BUGS & DEFICIENCIES

Pointers are tricky beasts, and there are myriad platform issues. At
this point, Pointer.pm is but a naive attempt at a novel idea. Hopefully
it can be fleshed out into a robust and serious module.

Support for pointers to structs is minimal, but is a primary design
goal. Pointer ships with a subclass for the sv struct as an example.
Expect better struct support in a future release.

If you have a good feel for C pointers, and grok where I am trying to go
with this module, please send me an email with your good ideas.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
