#!perl -T
use 5.006;
use Test::More;
use Encode qw/encode decode/;
use utf8;
use Cpanel::JSON::XS;
use Scalar::Util qw/refaddr/;
use Struct::WOP qw/all/ => { type => ['UTF-8', 'latin-1'], destruct => 1 };

BEGIN {
    use_ok( 'Struct::WOP' ) || print "Bail out!\n";
}

my $json = Cpanel::JSON::XS->new;

my $valid = $json->decode('[true, true, true, true, 500, "02", [], null]');
my $bool = \1;
my $data = $json->decode($json->encode([
	$bool,
	$bool,
	$bool,
	$bool,
	500,
	'02',
	[],
	undef
]));

is($json->encode(maybe_decode($data)), $json->encode($valid), "corrctly encoded utf8");  

my $vhash = {
	a => \0,
};

my $hash = {
	a => \0,
};

is($json->encode(maybe_decode($hash)), $json->encode($vhash), "correctly encoded utf8");

done_testing();
