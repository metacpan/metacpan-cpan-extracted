package RPC::Xmlrpc_c::Value;


=head1 NAME

RPC::Xmlrpc_c::Value - XML-RPC value

=head1 SYNOPSIS

 use RPC::Xmlrpc_c::Value;

 $addend = RPC::Xmlrpc_c::Value->newInt(7);
 
 $addend = RPC::Xmlrpc_c::Value->newI8(7);
 
 $addend = RPC::Xmlrpc_c::Value->newDouble(7);
 
 $finished = RPC::Xmlrpc_c::Value->newBool(1);
 
 $startTime = RPC::Xmlrpc_c::Value->newDatetime(time());
 
 $title = RPC::Xmlrpc_c::Value->newString('A Tale Of Two Cities');
 
 $flags = RPC::Xmlrpc_c::Value->newBytestring(pack('cccc', 1, 2, 3, 4));
 
 $parms = RPC::Xmlrpc_c::Value->newArray([$startTime, $title, $flags]);
 
 $parms = RPC::Xmlrpc_c::Value->newStruct({flags=>$flags, title=$title});
 
 $nil = RPC::Xmlrpc_c::Value->newNil();
 
 $parms = RPC::Xmlrpc_c::Value->newSimple([3, 'hello', {count=>5}]);

 $type = $addend->type();

 $value = $addend->value();

 @value = @{$parms->value()};

 %value = %{$parms->value()};

 $valueR = $parms->valueSimple();



=head1 DESCRIPTION

An object of this class can be used with C<RPC::Xmlrpc_c> facilities to
represent an XML-RPC value.  You find such objects as parameters of
XML-RPC calls and as XML-RPC results.

XML-RPC has stronger typing than Perl has, so this class is necessary
to allow you full flexibility in communicating with an XML-RPC client
or server.  For example, in Perl, there's no difference between the
string "3" and the number three.  But in XML-RPC, there is.  So if you
need to know whether a certain XML-RPC call returned "3" or three, you
need more than just a Perl scalar to tell you that.

However, if you don't need any more typing than Perl has, you can
use C<RPC::Xmlrpc_c> facilities that don't distinguish and therefore do
not use C<RPC::Xmlrpc_c::Value>.

Xmlrpc-c recognizes some types that aren't actually XML-RPC, but
extensions to XML-RPC.  In this documentation, we call them all
XML-RPC types.

There are one or more constructors for each of the XML-RPC types:

    newInt         32 bit integer  <i4>

    newI8          64 bit integer  <i8>

    newBool        boolean <bool>

    newString      string <string>

    newDouble      double-precision floating point <double>
 
    newDatetime    datetime <dateTime.iso8601>

    newNil         nil <nil>

    newBytestring  byte string <base64>

    newArray       array <array>

    newStruct      struct <struct> 

To find out which type your C<RPC::Xmlrpc_c::Value> is, use type().


If you have a C<RPC::Xmlrpc_c::Value> and want to get its value as regular
Perl data type, use value().  For example, if it's an integer
XML-RPC value, the return value is a regular Perl integer that you could
use in a Perl arithmetic expression.


If you don't need to differentiate the various XML-RPC types, you can
get the value of any compound XML-RPC value (a compound XML-RPC value
is one that involves structs or arrays) with valueSimple().  This
returns the entire compound value using only basic Perl types.
XML-RPC arrays turn into Perl array references, XML-RPC structs turn
into Perl hash references, and everything else converts as value()
would convert it.

=cut

use strict;
use warnings;
require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our $VERSION = '1.04';
our @EXPORT;
our @EXPORT_OK;
use Carp;
use Data::Dumper;

bootstrap RPC::Xmlrpc_c::Value $VERSION;



###############################################################################
#
# An object of class RPC::Xmlrpc_c::Value has these members:
#
#    _value: integer equivalent of the executable library handle (a
#            C pointer).  The RPC::Xmlprc-c::Value object owns one reference
#            to the executable library object.
#
###############################################################################



sub new($) {
# Caller must have a reference to the executable library object $_value,
# which becomes the reference from the Perl object to it
    
    my ($class, $_value) = @_;

    my $valueR = {};

    $valueR->{_value} = $_value;

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newInt($)

This is a constructor for an XML-RPC value of integer type.  (XML
element <i4>).

The argument is a normal Perl integer.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newInt(7);

=cut
sub newInt($) {

    my ($class, $value) = @_;

    my $valueR = {};

    _valueIntCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC integer value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newBool($)

This is a constructor for an XML-RPC value of boolean type.  (XML
element <boolean>).

The argument is a normal Perl integer: 0 or 1.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newBool(1);

=cut

sub newBool($) {
    my ($class, $value) = @_;

    my $valueR = {};

    _valueBoolCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC boolean value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newDouble($)

This is a constructor for an XML-RPC value of floating point type.  (XML
element <double>).

The argument is a normal Perl floating point number.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newDouble(1.7);

=cut

sub newDouble($) {
    my ($class, $value) = @_;
    
    my $valueR = {};

    _valueDoubleCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC double value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newDatetime($)

This is a constructor for an XML-RPC value of datetime type.  (XML
element <dateTime.iso8601>).

The argument is a datetime in the form that time() returns, i.e.
integer number of seconds since 1969 UTC, not counting leap seconds.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newDatetime(time());

=cut

sub newDatetime($) {
    my ($class, $value) = @_;

    my $valueR = {};

    _valueDatetimeCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC datetime value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newString($)

This is a constructor for an XML-RPC value of string type.  (XML
element <string>).

The argument is a regular Perl string.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newString('hello world');

=cut

sub newString($) {
    my ($class, $value) = @_;

    my $valueR = {};

    _valueStringCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC string value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newBytestring($)

This is a constructor for an XML-RPC value of byte string type.  (XML
element <base64>).

The argument is a Perl string in which each character represents the 
8 bits which are the encoding of that character in whatever encoding
Perl uses (so, typically, the character A is the 8 bits 0x41).

pack() is the typical way to create the argument.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newDatetime(pack('cccc', 1, 2, 3, 4));

=cut

sub newBytestring($) {
    my ($class, $value) = @_;

    my $valueR = {};

    _valueBytestringCreate($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC bytestring value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newArray($)

This is a constructor for an XML-RPC value of array type.  (XML
element <array>).

The argument is a reference to a Perl array.  Each element of that
array is a C<RPC::Xmlrpc_c::Value>.

Example:

    my $arrayR = [ RPC::Xmlrpc_c::Value->newInt(2),
                   RPC::Xmlrpc_c::Value->newInt(7),
                   RPC::Xmlrpc_c::Value->newInt(11) ];

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newArray($arrayR);

=cut

sub newArray($) {
    my ($class, $perlArrayR) = @_;

    my $valueR = {};

    if (ref($perlArrayR) ne 'ARRAY') {
        croak("RPC::Xmlrpc_c::Value::newArray() called with argument that " .
              "is not an array reference");
    }

    _valueArrayCreateEmpty(\my $_value, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC array value.  $error");
    }

    foreach my $item (@{$perlArrayR}) {
        if (ref($item) ne 'RPC::Xmlrpc_c::Value') {
            croak("An item in the array given to " .
                  "RPC::Xmlrpc_c::Value::newArray() is not a " .
                  "RPC::Xmlrpc_c::Value() object");
        }
        _arrayAppendItem($_value, $item->{_value}, \my $error);

        if ($error) {
            croak("Unable to append item to array.  $error");
        }
    }

    $valueR->{_value} = $_value;

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newStruct($)

This is a constructor for an XML-RPC value of structure type.  (XML
element <struct>).

The argument is a reference to a Perl hash.  Each key of the hash is
a strings which becomes a key of the XML-RPC structure.  The value for
a key of the hash is a C<RPC::Xmlrpc_c::Value> which becomes the value
for that key in the XML-RPC structure.

Example:

    my $structR = { red=>RPC::Xmlrpc_c::Value->newInt(1),
                    grn=>RPC::Xmlrpc_c::Value->newInt(1),
                    blu=>RPC::Xmlrpc_c::Value->newInt(2) };

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newStruct($structR);

=cut

sub newStruct($) {

    my ($class, $perlHashR) = @_;

    my $valueR = {};

    if (ref($perlHashR) ne 'HASH') {
        croak("RPC::Xmlrpc_c::Value::newArray() called with argument that " .
              "is not a hash reference");
    }

    _valueStructCreateEmpty(\my $_value, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC struct value.  $error");
    }

    while (my ($hashKey, $hashValue) = each(%{$perlHashR})) {
        if (ref($hashValue) ne 'RPC::Xmlrpc_c::Value') {
            croak("A value in the hash given to " .
                  "RPC::Xmlrpc_c::Value::newStruct() is not a " .
                  "RPC::Xmlrpc_c::Value() object");
        }
        _structSetValue($_value, $hashKey, $hashValue->{_value}, \my $error);
        
        if ($error) {
            croak("Unable to set value with key '$hashKey' in struct.  " .
                  "$error");
        }
    }

    $valueR->{_value} = $_value;

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newNil()

This is a constructor for an XML-RPC value of nil type.  (XML
element <nil>).

There are no arguments; a nil value, paradoxically, has no value.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::nil();

=cut

sub newNil() {
    my ($class) = @_;

    my $valueR = {};

    _valueNilCreate(\$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC nil value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



=head2 RPC::Xmlrpc_c::Value->newI8($)

This is a constructor for an XML-RPC value of 64 bit integer type.  (XML
element <i8>).

The argument is a normal Perl integer.

I don't fully understand how Perl deals with integers, but I believe
this doesn't actually work if the argument is an integer that won't
fit in 32 bits and your Perl interpreter is built for 32 bit words
(which essentially means you have a 32 bit CPU).

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newI8(7);

=cut

sub newI8($) {
    my ($class, $value) = @_;

    my $valueR = {};

    _valueI8Create($value, \$valueR->{_value}, \my $error);

    if ($error) {
        croak("Unable to create XML-RPC 8-byte integer value.  $error");
    }

    bless($valueR, $class);

    return $valueR;
}



sub newSimple($);   # Forward declaration for recursion



sub newSimpleArray($) {

    my ($class, $perlArrayR) = @_;

    my @valueArray;

    foreach (@{$perlArrayR}) {
        push (@valueArray, RPC::Xmlrpc_c::Value->newSimple($_));
    }
    return $class->newArray(\@valueArray);
}



sub newSimpleStruct($) {

    my ($class, $perlHashR) = @_;

    my %valueHash;

    while (my ($hashKey, $hashValue) = each(%{$perlHashR})) {
        $valueHash{$hashKey} = RPC::Xmlrpc_c::Value->newSimple($hashValue);
    }
    return $class->newStruct(\%valueHash);
}



=head2 RPC::Xmlrpc_c::Value->newSimple($)

This is a constructor for an XML-RPC value that represents the
specified basic Perl data structure without bothering the caller to
understand XML-RPC data types.  The constructor chooses types on its
own.

For a plain scalar value, not a reference and not undefined, it uses
an XML-RPC string.  For an undefined value, it uses an XML-RPC nil value.
For a reference to an array, it uses an XML-RPC array.  For a reference
to a hash, it uses an XML-RPC structure.  It builds compound values (those
with arrays and structures) recursively, so e.g. a Perl reference to an
array of references to arrays becomes an XML-RPC array of arrays.
Finally, for a RPC::Xmlrpc_c::Value, it just returns the same object.
This doesn't sound useful, but when you think about the recursiveness
mentioned above, it is.

Example:

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newSimple(7);

    $xmlrpcValue = RPC::Xmlrpc_c::Value->newSimple([7, 8, 9]);

This is highly convenient if both XML-RPC communicants are using this
same module -- one side uses newSimple(X) and the other uses ->value()
to recover X.  It's also useful when the protocol is simple or
flexible.  But if you need to produce an XML-RPC value of a particular
type, you have to use the other constructors and more lines of code.

Note that in the examples, the numbers become XML-RPC I<strings>,
which may not be what you need.  If these are parameters to an RPC where
the XML-RPC server expects XML-RPC integers, the server will fail the
RPC with a "wrong type parameter" error.  To do this right, you need
to use newInt().

=cut

sub newSimple($) {

    my ($class, $value) = @_;

    my $error;
    my $valueR;

    if (defined($value)) {
        my $reftype = ref($value);
        if ($reftype) {
            if ($reftype eq 'RPC::Xmlrpc_c::Value') {
                $valueR = $value;
            } elsif ($reftype eq 'ARRAY') {
                $valueR = RPC::Xmlrpc_c::Value->newSimpleArray($value);
            } elsif ($reftype eq 'HASH') {
                $valueR = RPC::Xmlrpc_c::Value->newSimpleStruct($value);
            } else {
                $error = "Value is reference to $reftype.  " .
                         "The only references that make sense in " .
                         "constructing an XML-RPC value are array and hash";
            }
        } else {
            $valueR = RPC::Xmlrpc_c::Value->newString($value);
        }
    } else {
        $valueR = RPC::Xmlrpc_c::Value->newNil();
    }

    if ($error) {
        croak("Unable to create XML-RPC 8-byte integer value.  $error");
    }

    return $valueR;
}



=head2 $xmlrpcValue->type()

This returns the type of the object, as one of the following strings,
with obvious association to the various XML-RPC data types:

    'int'
    'i8'
    'bool'
    'double'
    'string'
    'datetime'
    'bytestring'
    'nil'
    'array'
    'struct'

Example:

    if ($xmlrpcValue->type() eq 'string')
        print("it's a string: " . $xmlrpcValue->value() . "\n");

=cut

sub type() {
    my ($valueR) = @_;

    return _type($valueR->{_value});
}
push(@EXPORT_OK, 'type');


sub value_($);  # For recursive forward reference



sub valueArray_($) {
    my ($_value) = @_;
#-----------------------------------------------------------------------------
#  A reference to a Perl array of RPC::Xmlrpc_c::Value's, each being an
#  element of the XML-RPC array $_value.
# -----------------------------------------------------------------------------

    my $handlesR = _valueArray($_value);
        # This is a reference to a Perl array of handles to executable
        # library XML-RPC objects which are the elements of the
        # XML-RPC array.

    my @returnArray;

    foreach my $_item (@{$handlesR}) {
        push(@returnArray, RPC::Xmlrpc_c::Value->new($_item))
    }

    # The reference to the executable library object from $handlesR->[n]
    # is now the reference from $returnArray[n].

    return \@returnArray;
}



sub valueArraySimple_($) {
#-----------------------------------------------------------------------------
#  A Perl value equivalent to the executable XML-RPC array value whose handle
#  is $_value.  E.g. if it's an XML-RPC array of integers, we return a
#  reference to an array of integers.  (Our return value does not involve
#  RPC::Xmlrpc_c::Value in any way).
#-----------------------------------------------------------------------------
    my ($_value) = @_;

    my $arrayOfXmlRpcValueR = valueArray_($_value);
        # This is a reference to a Perl array of references to
        # RPC::Xmlrpc_c::Value's equivalent to the elements of the
        # RPC::Xmlrpc_c::Value array $_value.

    my @returnArray;

    foreach my $_item (@{$arrayOfXmlRpcValueR}) {
        push (@returnArray, valueSimple($_item));
    }

    return \@returnArray;
}



sub valueStruct_($) {
    my ($_value) = @_;
#-----------------------------------------------------------------------------
#  A reference to a Perl hash of RPC::Xmlrpc_c::Value's, each being a
#  value in the XML-RPC struct $_value.  Keys are strings.
# -----------------------------------------------------------------------------
    my $handlesR = _valueStruct($_value);
        # This is a reference to a Perl hash of handles to executable
        # library XML-RPC objects which are the elements of the
        # values of the XML-RPC struct members.  The hash keys are the
        # XML-RPC struct keys, as Perl strings.
        
    my %returnHash;

    while (my ($key, $_hashValue) = each(%{$handlesR})) {
        $returnHash{$key} = RPC::Xmlrpc_c::Value->new($_hashValue);
    }

    # The reference to the executable library object from $handlesR->{x}
    # is now the reference from $returnHash{x}.

    return \%returnHash;
}



sub valueStructSimple_($) {
#-----------------------------------------------------------------------------
#  A Perl value equivalent to the executable XML-RPC struct value whose handle
#  is $_value.  E.g. if it's an XML-RPC array of integers, we return a
#  reference to an array of integers.  (Our return value does not involve
#  RPC::Xmlrpc_c::Value in any way).
#-----------------------------------------------------------------------------
    my ($_value) = @_;

    my $hashOfXmlRpcValueR = valueStruct_($_value);
        # This is a reference to a Perl hash of references to
        # RPC::Xmlrpc_c::Value's equivalent to the elements of the
        # RPC::Xmlrpc_c::Value struct $_value.  Keys are the XML-RPC
        # struct keys as Perl strings.

    my %returnHash;

    while (my ($key, $_hashValue) = each(%{$hashOfXmlRpcValueR})) {
        $returnHash{$key} = valueSimple($_hashValue);
    }

    return \%returnHash;
}



sub value_($) {
#-----------------------------------------------------------------------------
#  Return the value of an XML-RPC value, as a regular Perl data structure,
#  given the handle of the executable library XML-RPC value object.
#-----------------------------------------------------------------------------
    my ($_value) = @_;

    my $retval;

    my $type = _type($_value);

    if (0) {
    } elsif ($type eq 'int') {
        $retval = _valueInt($_value);
    } elsif ($type eq 'bool') {
        $retval = _valueBool($_value);
    } elsif ($type eq 'double') {
        $retval = _valueDouble($_value);
    } elsif ($type eq 'datetime') {
        $retval = _valueDatetime($_value);
    } elsif ($type eq 'string') {
        $retval = _valueString($_value);
    } elsif ($type eq 'bytestring') {
        $retval = _valueBytestring($_value);
    } elsif ($type eq 'array') {
        $retval = valueArray_($_value);
    } elsif ($type eq 'struct') {
        $retval = valueStruct_($_value);
    } elsif ($type eq 'nil') {
        $retval = undef;
    } elsif ($type eq 'i8') {
        $retval = _valueI8($_value);
    } else {
        croak("_type() returned impossible type");
    }
    return $retval;
}



=head2 $xmlrpcValue->value()

This returns the value of the object, as a regular Perl data structure.

For the number, boolean, and string XML-RPC types, it returns a Perl
scalar in the obvious form (e.g.  C<value(newInt(5)) == 5> is true).

For an XML-RPC datetime, you get a value in the same form as the Perl time()
function returns, i.e. the number of seconds since 1969 not counting
leap seconds.

For an XML-RPC nil value, the return value is 'undef'.

For an XML-RPC array, you get a reference to an array of
C<RPC::Xmlrpc_c::Value>.  Each element in the array is an item from the
XML_RPC array (in the same order).

For an XML-RPC struct, you get a reference to a hash in which the keys
are the keys of the XML-RPC struct, as strings, and in which the values
are the values of the XML-RPC struct, as C<RPC::Xmlrpc_c::Value>.


Example:

    # assume you know $addend1 and $addend2 are RPC::Xmlprc_c::Value integers
    print("The sum is " . ($addend1->value() + $addend2->value()) . "\n");

=cut

sub value() {
    my ($valueR) = @_;

    return value_($valueR->{_value});
}
push(@EXPORT_OK, 'value');



sub valueSimple_($) {
    my ($_value) = @_;
#-----------------------------------------------------------------------------
#  A Perl value equivalent to the executable XML-RPC value whose handle is
#  $_value.  E.g. if it's an XML-RPC array of integers, we return a
#  reference to an array of integers.  (Our return value does not involve
#  RPC::Xmlrpc_c::Value in any way).
#-----------------------------------------------------------------------------
    if (!defined($_value)) {
        print("valueSimple_() got undefined argument\n");
    }
    my $retval;

    my $type = _type($_value);

    if (0) {
    } elsif ($type eq 'int') {
        $retval = _valueInt($_value);
    } elsif ($type eq 'bool') {
        $retval = _valueBool($_value);
    } elsif ($type eq 'double') {
        $retval = _valueDouble($_value);
    } elsif ($type eq 'datetime') {
        $retval = _valueDatetime($_value);
    } elsif ($type eq 'string') {
        $retval = _valueString($_value);
    } elsif ($type eq 'bytestring') {
        $retval = _valueBytestring($_value);
    } elsif ($type eq 'array') {
        $retval = valueArraySimple_($_value);
    } elsif ($type eq 'struct') {
        $retval = valueStructSimple_($_value);
    } elsif ($type eq 'nil') {
        $retval = undef;
    } elsif ($type eq 'i8') {
        $retval = _valueI8($_value);
    } else {
        croak("_type() returned impossible type");
    }
    return $retval;
}



=head2 $xmlrpcValue->valueSimple()

This returns the value of the object, as a regular Perl data structure.

It is like value(), except that for an array or structure, it returns
a data structure that is Perl all the way down; for example, if the
subject object is an XML-RPC array of arrays of integers, the return
value is a reference to a Perl array of references to Perl arrays of
Perl integers.

Example:

    # assume you know $array is a RPC::Xmlprc_c::Value array of integers
    print("Third element is " . $array->valueSimple->[3] . "\n");

where the $array->... part is equivalent to

    $array->value->[3]->value()

=cut

sub valueSimple($) {
    my ($valueR) = @_;

    return valueSimple_($valueR->{_value});
}
push(@EXPORT_OK, 'valueSimple');



sub DESTROY {
# This, by virtue of its name, is the destructor for a Value object.
# The Perl interpreter calls it when the last reference to the object
# goes away.
    my ($valueR) = @_;

    _valueDestroy($valueR->{_value});
}



1;
