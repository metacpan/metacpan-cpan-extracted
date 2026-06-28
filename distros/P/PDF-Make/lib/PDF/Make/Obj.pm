package PDF::Make::Obj;

use strict;
use warnings;

our $VERSION = '0.02';

# Load XS code from PDF::Make
use PDF::Make ();

# Export kind constants on request.
our @EXPORT_OK = qw(
    KIND_NULL KIND_BOOL KIND_INT KIND_REAL KIND_NAME KIND_STR
    KIND_ARRAY KIND_DICT KIND_STREAM KIND_REF
);
our %EXPORT_TAGS = (kinds => \@EXPORT_OK);

use Exporter 'import';

# Object kind constants matching pdfmake_kind_t enum.
use constant {
    KIND_NULL   => 0,
    KIND_BOOL   => 1,
    KIND_INT    => 2,
    KIND_REAL   => 3,
    KIND_NAME   => 4,
    KIND_STR    => 5,
    KIND_ARRAY  => 6,
    KIND_DICT   => 7,
    KIND_STREAM => 8,
    KIND_REF    => 9,
};

1;

__END__

=head1 NAME

PDF::Make::Obj - PDF object wrapper

=head1 SYNOPSIS

    use PDF::Make::Arena;
    use PDF::Make::Obj qw(:kinds);

    my $arena = PDF::Make::Arena->new;

    # Create objects
    my $int = $arena->int(42);
    my $str = $arena->str('Hello');

    # Type checking
    print $int->kind;       # 2 (KIND_INT)
    print $int->is_int;     # 1
    print $int->is_str;     # 0

    # Get value
    print $int->value;      # 42
    print $str->value;      # Hello

    # Array operations
    my $arr = $arena->array;
    $arr->push($int)->push($str);
    print $arr->len;        # 2
    my $first = $arr->get(0);

    # Dict operations
    my $dict = $arena->dict;
    $dict->set('Type', $arena->name('Catalog'));
    $dict->set('Count', $arena->int(1));
    print $dict->len;       # 2
    print $dict->has('Type'); # 1
    my $type = $dict->get('Type');

=head1 DESCRIPTION

C<PDF::Make::Obj> wraps PDF objects created via C<PDF::Make::Arena>.
Objects are arena-allocated and automatically freed when the arena
is destroyed.

=head1 METHODS

=head2 kind

    my $k = $obj->kind;

Return the object kind (see KIND_* constants).

=head2 Type Predicates

    $obj->is_null
    $obj->is_bool
    $obj->is_int
    $obj->is_real
    $obj->is_numeric   # int or real
    $obj->is_name
    $obj->is_str
    $obj->is_array
    $obj->is_dict
    $obj->is_stream
    $obj->is_ref

Return true if the object is of the specified type.

=head2 value

    my $val = $obj->value;

Return the scalar value for primitive types (null, bool, int, real,
name, str). Returns undef for composite types.

=head2 Array Methods

=head3 push

    $arr->push($obj);

Append an object to the array. Returns C<$self> for chaining.

=head3 len

    my $n = $arr->len;

Return the number of elements in the array.

=head3 get

    my $elem = $arr->get($index);

Return the element at the given index (0-based).

=head2 Dict Methods

=head3 set

    $dict->set($key, $obj);

Set a dictionary entry. C<$key> is a string (will be interned as a name).
Returns C<$self> for chaining.

=head3 get

    my $val = $dict->get($key);

Get the value for a key. Returns undef if not found.

=head3 has

    my $exists = $dict->has($key);

Return true if the key exists in the dictionary.

=head3 del

    $dict->del($key);

Delete a key from the dictionary.

=head3 len

    my $n = $dict->len;

Return the number of entries in the dictionary.

=head2 Ref Methods

=head3 ref_num

    my $num = $ref->ref_num;

Return the object number of an indirect reference.

=head3 ref_gen

    my $gen = $ref->ref_gen;

Return the generation number of an indirect reference.

=head1 CONSTANTS

=head2 :kinds

    use PDF::Make::Obj qw(:kinds);

=over 4

=item * C<KIND_NULL> (0)

=item * C<KIND_BOOL> (1)

=item * C<KIND_INT> (2)

=item * C<KIND_REAL> (3)

=item * C<KIND_NAME> (4)

=item * C<KIND_STR> (5)

=item * C<KIND_ARRAY> (6)

=item * C<KIND_DICT> (7)

=item * C<KIND_STREAM> (8)

=item * C<KIND_REF> (9)

=back

=head1 SEE ALSO

L<PDF::Make::Arena>, L<PDF::Make::Document>

=cut
