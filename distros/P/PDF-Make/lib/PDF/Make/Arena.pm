package PDF::Make::Arena;

use strict;
use warnings;

our $VERSION = '0.05';

# Load the XS code from PDF::Make
use PDF::Make ();

# XS bindings provide:
#   new()           - create a new arena
#   reset()         - reset arena for reuse
#   DESTROY()       - free arena
#
# Object creation methods (return PDF::Make::Obj):
#   null()          - create null object
#   bool($val)      - create boolean
#   int($val)       - create integer
#   real($val)      - create real number
#   name($str)      - create name
#   str($str)       - create literal string
#   hexstr($str)    - create hex string
#   obj_ref($num, $gen) - create indirect reference
#   array()         - create empty array
#   dict()          - create empty dictionary
#   stream()        - create empty stream

1;

__END__

=head1 NAME

PDF::Make::Arena - Memory arena for PDF object allocation

=head1 SYNOPSIS

    use PDF::Make::Arena;

    my $arena = PDF::Make::Arena->new;

    # Create primitive objects
    my $null = $arena->null;
    my $bool = $arena->bool(1);
    my $int  = $arena->int(42);
    my $real = $arena->real(3.14159);
    my $name = $arena->name('Type');
    my $str  = $arena->str('Hello, PDF!');
    my $hex  = $arena->hexstr("\x00\xFF");
    my $ref  = $arena->obj_ref(1, 0);  # 1 0 R

    # Create composite objects
    my $arr = $arena->array;
    $arr->push($int);
    $arr->push($str);

    my $dict = $arena->dict;
    $dict->set('Type', $arena->name('Catalog'));
    $dict->set('Pages', $arena->ref(2, 0));

    # Reset arena for reuse (frees all objects)
    $arena->reset;

=head1 DESCRIPTION

C<PDF::Make::Arena> provides a memory arena for allocating PDF objects.
All objects created from an arena share its memory pool and are freed
together when the arena is destroyed or reset.

This is a bump allocator optimized for the PDF document creation pattern
where many objects are allocated, used to generate output, and then freed
in bulk.

=head1 METHODS

=head2 new

    my $arena = PDF::Make::Arena->new;

Create a new memory arena.

=head2 reset

    $arena->reset;

Reset the arena, freeing all allocated objects while keeping the first
memory block for reuse. This is faster than destroying and recreating
the arena for batch operations.

=head2 null

    my $obj = $arena->null;

Create a PDF null object.

=head2 bool

    my $obj = $arena->bool(1);
    my $obj = $arena->bool(0);

Create a PDF boolean object.

=head2 int

    my $obj = $arena->int(42);

Create a PDF integer object.

=head2 real

    my $obj = $arena->real(3.14159);

Create a PDF real (floating point) object.

=head2 name

    my $obj = $arena->name('Type');

Create a PDF name object. Names are interned for efficient comparison.

=head2 str

    my $obj = $arena->str('Hello');

Create a PDF literal string object.

=head2 hexstr

    my $obj = $arena->hexstr("\x00\xFF");

Create a PDF hexadecimal string object.

=head2 obj_ref

    my $obj = $arena->obj_ref($num, $gen);
    my $obj = $arena->obj_ref($num);  # gen defaults to 0

Create a PDF indirect reference (N G R).

=head2 array

    my $arr = $arena->array;

Create an empty PDF array. Use C<push> to add elements.

=head2 dict

    my $dict = $arena->dict;

Create an empty PDF dictionary. Use C<set> to add entries.

=head2 stream

    my $stream = $arena->stream;

Create an empty PDF stream object.

=head1 MEMORY MANAGEMENT

Objects created from an arena are only valid while the arena exists.
When the arena is destroyed or reset, all objects become invalid.

The arena keeps internal references to ensure objects remain valid
as long as they're referenced from Perl.

=head1 SEE ALSO

L<PDF::Make::Obj>, L<PDF::Make::Document>

=cut
