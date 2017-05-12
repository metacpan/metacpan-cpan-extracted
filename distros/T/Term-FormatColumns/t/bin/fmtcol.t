
use Test::More;
use FindBin ();
my $script = "$FindBin::Bin/../../bin/fmtcol";
require $script;
$0 = $script; # So pod2usage finds the right file

my $output;
open my $fh, '>', \$output or die "Could not open string for writing";
local *STDOUT = $fh;

open my $stdin, '<', \"foo\nbar\nbaz\nbiz\nblargh\nfizzbuzz\n"
    or die "Could not open string for reading: $!";
local *STDIN = $stdin;

my $exit = fmtcol->main( '-w', '20' );
is $output, <<'TESTOUTPUT', 'input on stdin';
foo       biz
bar       blargh
baz       fizzbuzz
TESTOUTPUT

$output = undef;
seek $fh, 0, 0;

my $exit = fmtcol->main( '-w', '20', "$FindBin::Bin/../share/input.txt" );
is $output, <<'TESTOUTPUT', 'input from a file';
foo       biz
bar       blargh
baz       fizzbuzz
TESTOUTPUT

done_testing;
