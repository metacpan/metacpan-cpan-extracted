#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use File::Path qw(make_path);
use TestCerts;
use Monitoring::Sneck::Checks;

my $dir = TestTmp::dir();
make_path( $dir . '/ssl/sub' );
my $paths = TestCerts::make(
	$dir . '/ssl',
	{ name => 'www',   days => 20, names => ['www.example.org'] },
	{ name => 'other', days => 90, names => ['other.example.org'] },
);
TestCerts::make( $dir . '/ssl/sub', { name => 'deep', days => 3, names => ['deep.example.org'] } );
symlink( $paths->{www} . '.pem', $dir . '/ssl/www-link.pem' );
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'cert_dir', args => [@_] ) };

# ca, www, other, and both chains, the link to www skipped, keys not matching
my $return = $run->( '-d', $dir . '/ssl' );
is( $return->{code}, 1, 'www at 20 days is WARNING' );
like(
	$return->{stdout},
	qr/\ACERT_DIR WARNING - 7 certificates in 5 files in \S+, 2 not OK, soonest \S+\/www-chain.pem #1 "www.example.org" expires in 20 days, [^|]+ \| days=20;30;14 certificates=7;;;0\n\S+www-chain.pem #1 "www.example.org" expires in 20 days[^\n]+\n\S+\/www.pem "www.example.org" expires in 20 days[^\n]+\n\z/,
	'output, with a line for each not OK'
);
is( $run->( '-d', $dir . '/ssl', '-w', 10, '-c', 5 )->{code}, 0, 'OK' );
$return = $run->( '-d', $dir . '/ssl', '-r', '-w', 10, '-c', 5 );
is( $return->{code}, 2, '-r finds the one under' );
like(
	$return->{stdout},
	qr/, soonest \S+\/sub\/deep-chain.pem #1 "deep.example.org" expires in 3 days/,
	'as the soonest'
);
like( $run->( '-d', $dir . '/ssl', '-m', 'other' )->{stdout}, qr/ - 3 certificates in 2 files in/, '--match' );

# problems
like(
	$run->( '-d', $dir . '/nope' )->{stdout},
	qr/\ACERT_DIR CRITICAL - no certificates in \S+\/nope\ncan not read \S+\/nope\n\z/,
	'missing directory'
);
like(
	$run->( '-d', $dir . '/ssl/sub', '-m', '\.key$' )->{stdout},
	qr/\ACERT_DIR UNKNOWN - no certificates in/,
	'no certificates'
);
open( my $fh, '>', $dir . '/ssl/sub/garbage.pem' ) or die($!);
print $fh "-----BEGIN CERTIFICATE-----\nbm90IGEgY2VydA==\n-----END CERTIFICATE-----\n";
close($fh);
like(
	$run->( '-d', $dir . '/ssl/sub', '-w', 1, '-c', 0 )->{stdout},
	qr/\ACERT_DIR UNKNOWN - .*\n\S+garbage.pem can not be parsed\n/,
	'not parsable is UNKNOWN'
);
is( $run->( '-d', $dir, '-m', '(' )->{code}, 3, 'bad --match' );

done_testing();
