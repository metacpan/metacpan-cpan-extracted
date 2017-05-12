use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib3');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
#    all_ok(search_path => 'MyApp3', check => sub { die "wow!"; }); # will fail
#    all_ok(search_path => 'MyApp3', use => 1); # will fail
     all_ok(search_path => 'MyApp', use => 1); # will success
}