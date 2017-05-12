#! perl
#
# 04-search.t
#
# Testsuite for the search() method, which is compatible with the
# same-named method in Mojo::Loader.
#
# It hard-codes the search depth to 1.
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use File::Spec::Functions qw/ catfile /;
BEGIN {
    # OS-portable version of "use lib 't/lib';"
    # Otherwise this test will fail on Win32
    push(@INC, catfile('t', 'lib'));
}
use Module::Loader;

my ($loader, @modules);

$loader = Module::Loader->new(max_depth => 5)
          || BAIL_OUT("Can't instantiate Module::Loader");

@modules = $loader->search('Monkey::Plugin');

ok(grep({ $_ eq 'Monkey::Plugin::Bonobo' } @modules),
   "We should find Monkey::Plugin::Bonobo");

ok(!grep({ $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules),
   "We should NOT find Monkey::Plugin::Bonobo::Utilities");

ok(grep({ $_ eq 'Monkey::Plugin::Mandrill' } @modules),
   "We should find Monkey::Plugin::Bonobo::Utilities");

@modules = $loader->search('Monkey::Plugin');

ok(grep({ $_ eq 'Monkey::Plugin::Bonobo' } @modules),
   "We should find Monkey::Plugin::Bonobo");

ok(!grep({ $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules),
   "We should NOT find Monkey::Plugin::Bonobo::Utilities");

ok(grep({ $_ eq 'Monkey::Plugin::Mandrill' } @modules),
   "We should find Monkey::Plugin::Bonobo::Utilities");

@modules = $loader->find_modules('Monkey::Plugin');

ok(grep({ $_ eq 'Monkey::Plugin::Bonobo' } @modules),
   "We should find Monkey::Plugin::Bonobo");

ok(grep({ $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules),
   "We should find Monkey::Plugin::Bonobo::Utilities");

ok(grep({ $_ eq 'Monkey::Plugin::Mandrill' } @modules),
   "We should find Monkey::Plugin::Bonobo::Utilities");

# Without changing max_depth, it should still have value 5,
# even though we've used search() after setting max_depth.

ok($loader->max_depth == 5, "max_depth should still be set to 5");

done_testing;

