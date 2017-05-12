package TestBaseTest;
use Test::Base -Base;

use File::Path qw(rmtree);
my $t = -e 't' ? 't' : 'test';
rmtree("$t/output");

