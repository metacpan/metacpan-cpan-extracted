#!perl -Tw

use strict;

use Test::More qw(no_plan);

use SeeAlso::Identifier::ISBN;
use Business::ISBN;

my $isbn = SeeAlso::Identifier::ISBN->new("978-0-596-52724-2");
isa_ok( $isbn, 'SeeAlso::Identifier::ISBN' );
ok ( $isbn, 'new ISBN' );

my @equal = (
    'urn:isbn:9780596527242', 'URN:ISBN:0596527241',
    '978-0-596-52724-2', '0596527241',
    Business::ISBN->new('0596527241')
);

for(my $i=0; $i<@equal; $i++) {
    my $v = $equal[$i];
    $isbn->value( $v );
    ok( $isbn->valid, "valid value: $v" );
    is( $isbn, SeeAlso::Identifier::ISBN->new( $equal[0] ), "equal: $v" );
}

is( $isbn->isbn13, '9780596527242', "isbn13" );
is( $isbn->isbn10, '0596527241', "isbn10" );

my %values = (
    '0-8044-2957-x' => 'urn:isbn:9780804429573'
);

foreach my $from (keys %values) {
    $isbn = new SeeAlso::Identifier::ISBN( $from );
    ok ( $isbn, "valid value: $from" );
    is ( $isbn->normalized, $values{$from}, "URI (normalized)" );
    is ( $isbn->canonical, $values{$from}, "URI (canonical)" );
}

is( SeeAlso::Identifier::ISBN->new('0-8044-2957-x')->value, '9780804429573', 'value' );

# invalid ISBN-10
$isbn = SeeAlso::Identifier::ISBN->new('1234567891');
ok ( !$isbn->valid, "invalid ISBN-10" );

# invalid ISBN-13
$isbn = SeeAlso::Identifier::ISBN->new('978-1-84545-309-3');
ok ( !$isbn->valid, "invalid ISBN-13" );

# valid ISBN-10
my $i = "9991372539";
$isbn = SeeAlso::Identifier::ISBN->new("9991372539");
ok ( $isbn->valid, "valid ISBN: $i" );

# additional spaces
$isbn->value('  0596527241 ');
ok( $isbn->valid, 'additional spaces' );

# uri
$isbn->value('urn:isbn:9780596527242');
ok( $isbn->valid , 'urn:isbn' );

is( $isbn->hash, 59652724, 'get hash');

my @invalid = (-1, 2000000000, '', undef, "abc");
foreach (@invalid) {
    $isbn->hash($_);
    ok( !$isbn, "invalid hash: " . (defined $_ ? $_ : 'undef') );
}

my %valid = (
    0 => 'urn:isbn:9780000000002',
    999999999 => 'urn:isbn:9789999999991',
    1999999999 => 'urn:isbn:9799999999990',
    59652724 => 'urn:isbn:9780596527242'
);
foreach my $hash (keys %valid) {
    $isbn->hash( $hash );
    ok( $isbn, "valid hash: $hash" );
    is( $hash, $isbn->hash, "valid hash: $hash" );
    is( $isbn, $valid{$hash}, "hash $hash = $isbn" );
}
