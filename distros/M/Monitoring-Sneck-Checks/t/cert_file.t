#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use TestCerts;
use Monitoring::Sneck::Checks;

my $dir   = TestTmp::dir();
my $paths = TestCerts::make(
	$dir,
	{ name => 'www',   days => 20, names => [ 'www.example.org', 'example.org' ] },
	{ name => 'other', days => 90, names => ['other.example.org'] },
);
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'cert_file', args => [@_] ) };

my $return = $run->( '-f', $paths->{www} . '.pem' );
is( $return->{code}, 1, '20 days left is WARNING' );
like(
	$return->{stdout},
	qr/\ACERT_FILE WARNING - \Q$paths->{www}\E.pem "www.example.org" expires in 20 days, [0-9: -]+ UTC \| days=20;30;14\n\z/,
	'output'
);
is( $run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5 )->{code}, 0, 'OK' );
is( $run->( '-f', $paths->{www} . '.pem', '-c', 25 )->{code}, 2, 'CRITICAL' );

$return = $run->( '-f', $paths->{other} . '-chain.pem', '-w', 100, '-c', 10 );
is( $return->{code}, 1, 'chain, leaf WARNING' );
like(
	$return->{stdout},
	qr/\A[^\n]+\n\Q$paths->{other}\E-chain.pem #1 [^\n]+\n\Q$paths->{other}\E-chain.pem #2 "Test CA" expires in 36[45] days/,
	'each certificate in it listed'
);
like(
	$run->( '-f', $paths->{other} . '-chain.pem', '-w', 400, '-c', 10 )->{stdout},
	qr/, \S+ #2 "Test CA" expires in/,
	'a later certificate not OK is in the status line'
);

# names and keys
is(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-n', 'example.org', '-n', 'www.example.org' )->{code},
	0,
	'covers names'
);
like(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-n', 'shop.example.org' )->{stdout},
	qr/CRITICAL - .*, does not cover shop.example.org/,
	'name not covered'
);
is( $run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-k', $paths->{www} . '.key' )->{code}, 0, 'key matches' );
like(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-k', $paths->{other} . '.key' )->{stdout},
	qr/CRITICAL - .*, \Q$paths->{other}\E.key does not match/,
	'key does not match'
);
like(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-k', $paths->{www} . '.pem' )->{stdout},
	qr/is not a key, or is encrypted/,
	'not a key'
);
like(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-k', $dir . '/nope.key' )->{stdout},
	qr/can not read \Q$dir\E\/nope.key/,
	'no key'
);
chmod( 0644, $paths->{www} . '.key' );
like(
	$run->( '-f', $paths->{www} . '.pem', '-w', 10, '-c', 5, '-k', $paths->{www} . '.key' )->{stdout},
	qr/\ACERT_FILE WARNING - .*\.key is readable by everyone/,
	'key readable by everyone'
);

# bad files
like( $run->( '-f', $dir . '/nope.pem' )->{stdout}, qr/\ACERT_FILE CRITICAL - can not read/, 'missing' );
like(
	$run->( '-f', $paths->{www} . '.key' )->{stdout},
	qr/\ACERT_FILE CRITICAL - no certificates in/,
	'no certificates'
);
like(
	$run->( '-f', $FindBin::Bin . '/data/cert_file/garbage.pem' )->{stdout},
	qr/garbage.pem can not be parsed/,
	'not parsable'
);
is( $run->()->{code}, 3, 'no --file' );

done_testing();
