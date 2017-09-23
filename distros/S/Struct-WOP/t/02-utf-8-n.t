#!perl -T
use 5.006;
use Test::More;
use Encode qw/encode decode/;
use utf8;
use JSON;
use Scalar::Util qw/refaddr/;
use Struct::WOP qw/all/ => { type => ['UTF-8', 'latin-1'] };

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
$data = maybe_decode($data);
$data->[2] = ${$data->[2]};
is_deeply($data, $valid, "corrctly decoded utf8");  

my $vhash = {
	a => 'ß',
};

my $hash = {
	a => encode('UTF-8', 'ß'),
};

is_deeply(maybe_decode($hash), $vhash, "correctly decoded utf8");

done_testing();
