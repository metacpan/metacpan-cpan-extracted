#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use Digest::SHA qw(sha256_hex sha512_hex sha1_hex);
use Digest::MD5 qw(md5_hex);
use Monitoring::Sneck::Checks;

my $dir   = TestTmp::dir();
my $write = sub {
	my ( $name, $content ) = @_;
	open( my $fh, '>', $dir . '/' . $name ) or die($!);
	print $fh $content;
	close($fh);
	return $dir . '/' . $name;
};
my $run = sub { return Monitoring::Sneck::Checks->run( check => 'checksums', args => [@_] ) };

my $one   = $write->( 'one',       "first file\n" );
my $two   = $write->( 'two',       "second file\n" );
my $space = $write->( 'has space', "third\n" );
my $list  = $write->(
	'sums.sha256',
	"# made by sha256sum\n\n"
		. sha256_hex("first file\n") . '  '
		. $one . "\n"
		. sha256_hex("second file\n") . ' *'
		. $two . "\n"
);
my $bsd = $write->(
	'sums.bsd',
	'SHA512 ('
		. $space . ') = '
		. uc( sha512_hex("third\n") )
		. "\nMD5 ("
		. $one . ') = '
		. md5_hex("first file\n") . "\n"
);

my $return = $run->( '-l', $list, '-l', $bsd, '-F', $two . '=' . sha1_hex("second file\n") );
is( $return->{code},   0,                                                       'every format matching' );
is( $return->{stdout}, "CHECKSUMS OK - 5 of 5 files match | matched=5;;;0;5\n", 'output' );

$write->( 'two', "changed\n" );
unlink($one);
$return = $run->( '-l', $list );
is( $return->{code}, 2, 'changed and missing are CRITICAL' );
is(
	$return->{stdout},
	"CHECKSUMS CRITICAL - 0 of 2 files match, 2 do not | matched=0;;;0;2\ncan not read $one, No such file or directory\n$two does not match its sha256\n",
	'and each said'
);

$write->( 'bad.sums', "not a checksum line\n" . 'SHA256 (' . $two . ') = ' . md5_hex('x') . "\n" );
like(
	$run->( '-l', $write->( 'bad.sums', "not a checksum line\n" ) )->{stdout},
	qr/\ACHECKSUMS UNKNOWN - 0 of 0 files match, \S+bad.sums line 1 is not understood/,
	'a line not understood'
);
like(
	$run->( '-l', $write->( 'tag.sums', 'SHA256 (' . $two . ') = ' . md5_hex('x') . "\n" ) )->{stdout},
	qr/tag.sums line 1 is not understood/,
	'a tag not matching the length'
);
like(
	$run->( '-l', $dir . '/nope' )->{stdout},
	qr/\ACHECKSUMS UNKNOWN - 0 of 0 files match, can not read \S+nope/,
	'list missing'
);
like( $run->( '-F', $dir . '=' . md5_hex('x') )->{stdout}, qr/is not a file/, 'a directory' );
is( $run->()->{code},                      3, 'nothing to check' );
is( $run->( '-F', $two . '=abc' )->{code}, 3, 'bad --file' );

done_testing();
