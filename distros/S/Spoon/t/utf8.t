use lib 't', 'lib';
use strict;
use warnings;
use Test::More;

eval "use Encode";
if($@) {
	plan skip_all => "Encode not installed.";
}

use Spoon::Base;

plan tests => 5;

my $data = "\xE1\x9A\xA0\xE1\x9B\x87\xE1\x9A\xBB";

ok( ! Encode::is_utf8($data), 'data is not marked as UTF8' );
is( length $data, 9, 'undecoded data is 9 chars long' );

Spoon::Base->utf8_decode($data);

ok( Encode::is_utf8($data), 'data is marked as UTF8' );
is( length $data, 3, 'decoded data is 3 chars long' );
is( $data, "\x{16A0}\x{16C7}\x{16BB}", 'check string content after decoding' );


