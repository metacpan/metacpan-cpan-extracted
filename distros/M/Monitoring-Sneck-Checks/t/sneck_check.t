#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;

my @perl   = ( $^X, '-I' . $FindBin::Bin . '/../lib', '-I' . $FindBin::Bin . '/lib' );
my $script = $FindBin::Bin . '/../src_bin/sneck_check';

my $output = `@perl $script testing --code 2 --out hello --err oops`;
is( $? >> 8, 2,               'exits with the code' );
is( $output, "hello\noops\n", 'prints combined' );
$output = `@perl $script -a testing --out hello --err oops`;
is( $output, "stdout:\nhello\nstderr:\noops\n", '-a prints them apart' );
`@perl $script base 2>&1`;
is( $? >> 8, 3, 'not loaded exits 3' );
`@perl $script 2>&1`;
is( $? >> 8, 3, 'no check exits 3' );

# help, for the script and for a check
foreach my $flag ( '-h', '--help' ) {
	$output = `@perl $script $flag`;
	is( $? >> 8, 0, $flag . ' exits 0' );
	like( $output, qr/sneck_check - runs a Monitoring::Sneck::Checks check/, 'and prints its own docs' );
	foreach my $args ( $flag . ' file_mode', 'file_mode ' . $flag, 'file_mode -f /etc/passwd ' . $flag ) {
		$output = `@perl $script $args`;
		is( $? >> 8, 0, $args . ' exits 0' );
		like( $output, qr/Monitoring::Sneck::Checks::file_mode - checks the mode/, 'and prints the docs of the check' );
		like( $output, qr/--ignore-missing/,                                       'with its options' );
		like( $output, qr/--timeout/,                                              'and the common ones' );
		unlike( $output, qr/^Methods:/m, 'but not its methods' );
	}
} ## end foreach my $flag ( '-h', '--help' )
foreach my $bad ( 'base', 'no_such_check', 'Bad' ) {
	$output = `@perl $script --help $bad 2>&1`;
	is( $? >> 8, 3, '--help ' . $bad . ' exits 3' );
	unlike( $output, qr/Options:/, 'and prints no docs' );
}

# listing them
foreach my $flag ( '-l', '--list-checks' ) {
	$output = `@perl $script $flag`;
	is( $? >> 8, 0, $flag . ' exits 0' );
	like( $output, qr/^file_mode :: checks the mode, owner, and group of files$/m,
		'lists a check with what it is for' );
	like( $output, qr/^testing$/m, 'and one with no POD by name alone' );
	unlike( $output, qr/^base\b/m, 'but not base' );
}

done_testing();
