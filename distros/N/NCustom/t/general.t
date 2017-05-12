# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;

use File::Path ;
use File::Copy ;
use vars qw($output $input);

# test setup
$output = "./t/general.o";
$input = "./t/general.i";
rmtree  $output;
mkpath  $output;
$ENV{HOME} = $output ; # lets be non-intrusive

use_ok('NCustom');

# test teardown
#rmtree  $output;
#mkpath  $output;

#end#
