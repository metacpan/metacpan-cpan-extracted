use strict;
use warnings;

use Test::More tests => 1;

use Module::Find;

use lib qw(./t/test ./t/test/duplicates);

# Ensure duplicate modules are only reported once
my @l = useall ModuleFindTest;
ok($#l == 1);