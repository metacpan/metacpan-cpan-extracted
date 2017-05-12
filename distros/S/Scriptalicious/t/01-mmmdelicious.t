# -*- perl -*-

use Test::More tests => 9;

BEGIN {
    use_ok( 'Scriptalicious', -progname => "myscript" );
}

start_timer;

is($PROGNAME, "myscript", "got PROGNAME ok");

my $string;
{
    local(@ARGV) = ("-v", "-s", "foo");
    getopt("string|s=s" => \$string);
}

is($VERBOSE, 1, "Parsed built-in argument");
is($string, "foo", "Parsed custom argument");

$VERBOSE = 0;
( -e "t/testfile" ) && do { unlink("t/testfile")
				|| die "Can't unlink t/testfile; $!" };
run("touch", "t/testfile");
ok( -f "t/testfile", "run()");
unlink("t/testfile");

my ($error, @output) = capture_err("head -5 $0");

my $output = join "", @output;

is($error, 0, "capture_err() - error code");
is($output, `head -5 $0`, "capture_err() - output");

like(show_delta, qr/^\d+(\.\d+)?[mu]?s$/, "show_delta");
like(show_elapsed, qr/^\d+(\.\d+)?[mu]?s$/, "show_elapsed");
