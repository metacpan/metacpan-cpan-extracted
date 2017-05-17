#!perl -T
use 5.016;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 21;
    use_ok( 'Net::DNS::Extlang' ) || print "Bail out!\n";
}

# use my DNS zone
#$Net::DNS::Parameters::DNSEXTLANG = 'services.net.';

diag( "Testing Net::DNS::Extlang $Net::DNS::Extlang::VERSION, Perl $], $^X" );

my $xl = new Net::DNS::Extlang(domain => 'services.net');
ok($xl,					'create extlang from DNS');
my $lxl = new Net::DNS::Extlang(file => 't/rrtypes.txt.xdup');
ok($lxl,				'create extlang from file');

# rrtype from DNS
my $xa = $xl->getrr('XA');
ok($xa,					'get XA record from DNS');
is($xa->{mnemon},'XA',			'DNS XA has right rrname');
is($xa->{number}, 4097,			'DNS XA has right number');
is($xa->{fields}[0]->{type}, 'A',	'DNS XA has right field type');

$xa = $xl->getrr(4097);
ok($xa,					'get 4097 record from DNS');
is($xa->{mnemon},'XA',			'DNS 4097 has right rrname');
is($xa->{number}, 4097,			'DNS 4097 has right number');
is($xa->{fields}[0]->{type}, 'A',	'DNS 4097 has right field type');

# rrtype from file
my $lxa = $lxl->getrr('XA');
ok($lxa,				'get XA record from file');
is($lxa->{mnemon},'XA',			'file XA has right rrname');
is($lxa->{number}, 4097,		'file XA has right number');
is($lxa->{fields}[0]->{type}, 'A',	'file XA has right field type');

$lxa = $lxl->getrr(4097);
ok($lxa,				'get 4097 record from file');
is($lxa->{mnemon},'XA',			'file 4097 has right rrname');
is($lxa->{number}, 4097,		'file 4097 has right number');
is($lxa->{fields}[0]->{type}, 'A',	'file 4097 has right field type');

# smoke test compiling
my $xc = $xl->compile('AAAA');
ok($xc,					'compile AAAA');
$xc = $xl->compilerr($lxa);
ok($xc,					'compile 4097 rrr');
