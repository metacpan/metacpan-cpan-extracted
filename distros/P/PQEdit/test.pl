# perl

require 5.003;

use Getopt::Std 'getopts';
use Config '%Config';
getopts(':p:');

$perl = $opt_p || $^X;

if( ! -f $perl ){ die "Where's Perl? $perl" }

my($test1_out);
open(TSTFILE,"$perl pqedit.cgi < t/test1.in 2>/dev/null |");
while(<TSTFILE>) {
    s/\r//g;
    $test1_out .= $_;
}
close(TSTFILE);
if ($test1_out =~ /Status:\s*200\s*OK/ &&
    $test1_out =~ /JavaScript/ &&
    $test1_out =~ /ACTION=.*pqedit\.cgi/ &&
    $test1_out =~ /NAME=\"server\"/ &&
    $test1_out =~ /<\/HTML>/) {
    print "Test Login Panel: ok\n";
    1;
} else {
    print "Test Login Panel: failed\n";
    0;
}
