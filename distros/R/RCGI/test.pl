# perl

require 5.003;

use Getopt::Std 'getopts';
use Config '%Config';
getopts(':p:');

$perl = $opt_p || $^X;

if( ! -f $perl ){ die "Where's Perl? $perl" }

# "$perl test_script";
1;
