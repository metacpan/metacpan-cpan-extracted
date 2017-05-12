use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok('Switch::Reftype', ':all') };

my $scalar = "Hello, World!";
*scalar or 0;   # Suppress "only used once" warning
my $ref = \$scalar;
format TestFormat =
.
my %reference = (
    SCALAR  => \$scalar,
    ARRAY   => [$scalar],
    HASH    => {key => $scalar},
    CODE    => sub { $scalar },
    REF     => \$ref,
    GLOB    => \*scalar,
    LVALUE  => \substr($scalar, 0, length($scalar)),
    FORMAT  => *TestFormat{FORMAT},
    IO      => *STDOUT{IO},
    VSTRING => \v127.0.0.1,
    REGEXP  => qr/$scalar/
);
my %result = (
    SCALAR  => (if_SCALAR   { $$_ }         $reference{SCALAR}  ),
    ARRAY   => (if_ARRAY    { $_->[0] }     $reference{ARRAY}   ),
    HASH    => (if_HASH     { $_->{key} }   $reference{HASH}    ),
    CODE    => (if_CODE     { $_->() }      $reference{CODE}    ),
    REF     => (if_REF      { $$$_ }        $reference{REF}     ),
    GLOB    => (if_GLOB     { $scalar }     $reference{GLOB}    ),
    LVALUE  => (if_LVALUE   { $$_ }         $reference{LVALUE}  ),
    FORMAT  => (if_FORMAT   { $scalar}      $reference{FORMAT}  ),
    IO      => (if_IO       { $scalar }     $reference{IO}      ),
    VSTRING => (if_VSTRING  { $scalar}      $reference{VSTRING} ),
    REGEXP  => (if_REGEXP   { $scalar }     $reference{REGEXP}  )
);

# Test if we have the same number of keys for both %reference and %result
ok(keys %result == keys %reference, "identical number of keys");

# Test all the if_X functions (if_SCALAR, if_ARRAY, etc)
is($result{$_}, $scalar, "if_$_") for keys %result;

# Test if non-reference scalars test as 'scalar'
$scalar = switch_reftype("foo",
    default => sub {"Scalar"}
);    
is($scalar, "Scalar", "non-refs test as 'scalar'");

# Test if undef values test as 'undef'
$scalar = switch_reftype(undef,
    undef   => sub {"Undef"}
);
is($scalar, "Undef", "undef tests as 'undef'");

# Test if non-specified reftypes test as 'default'
$scalar = switch_reftype(\1,
    ARRAY => sub {"Array reference"},
    default => sub {"Default"}
);
is($scalar, "Default", "non-specified reftype tests as 'default'");    

0;