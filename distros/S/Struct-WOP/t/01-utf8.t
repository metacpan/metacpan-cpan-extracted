#!perl -T
use 5.006;
use Test::More;
use Encode qw/encode decode/;
use utf8;
use JSON;
use Scalar::Util qw/refaddr/;
use Struct::WOP qw/all/ => { type => ['UTF-8', 'latin-1'], destruct => 1 };

BEGIN {
    use_ok( 'Struct::WOP' ) || print "Bail out!\n";
}

my $valid = [
	'ç∂ß',
	'ç∂ß',
	'ß',
	\1,
];

my $scala = \encode('UTF-8', 'ß');
my $bool = \1;
my $data = [
	'ç∂ß',
	encode('UTF-8', 'ç∂ß'),
	$scala,
	$bool
];

my $json = JSON->new->utf8;
is($json->encode(maybe_decode($data)), $json->encode($valid), "corrctly encoded utf8");  

my $vhash = {
	a => 'ß',
};

my $hash = {
	a => encode('UTF-8', 'ß'),
};

is($json->encode(maybe_decode($hash)), $json->encode($vhash), "correctly encoded utf8");

done_testing();
