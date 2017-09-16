#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Encode qw/encode decode/;
use utf8;
use JSON;

use Struct::WOP qw/all/ => { type => ['UTF-8', 'latin-1'], destruct => 1 };

BEGIN {
    use_ok( 'Struct::WOP' ) || print "Bail out!\n";
}

my $valid = [
	'ç∂ß',
	'ç∂ß',
];

my $data = [
	'ç∂ß',
	encode('UTF-8', 'ç∂ß'),
];

my $json = JSON->new->utf8;
is($json->encode(maybe_decode($data)), $json->encode($valid), "corrctly encoded utf8");  

my $hash = {
	a => 'ß'
};

done_testing();
