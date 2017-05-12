#! perl

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
use Plugin::Loader;

my ($loader, @modules);

$loader = Plugin::Loader->new()
          || BAIL_OUT("Can't instantiate Plugin::Loader");

@modules = $loader->find_modules('Monkey::Plugin');

ok(grep { $_ eq 'Monkey::Plugin::Bonobo' } @modules,
   "We should find Monkey::Plugin::Bonobo");

ok(grep { $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules,
   "We should find Monkey::Plugin::Bonobo::Utilities");

ok(grep { $_ eq 'Monkey::Plugin::Mandrill' } @modules,
   "We should find Monkey::Plugin::Bonobo::Utilities");

$loader->max_depth(1);
@modules = $loader->find_modules('Monkey::Plugin');

ok(grep { $_ eq 'Monkey::Plugin::Bonobo' } @modules,
   "We should find Monkey::Plugin::Bonobo");

ok(!grep { $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules,
   "We should NOT find Monkey::Plugin::Bonobo::Utilities");

ok(grep { $_ eq 'Monkey::Plugin::Mandrill' } @modules,
   "We should find Monkey::Plugin::Bonobo::Utilities");

$loader->max_depth(0);
@modules = $loader->find_modules('Monkey::Plugin');

ok(grep { $_ eq 'Monkey::Plugin::Bonobo' } @modules,
   "We should find Monkey::Plugin::Bonobo");

ok(grep { $_ eq 'Monkey::Plugin::Bonobo::Utilities' } @modules,
   "We should find Monkey::Plugin::Bonobo::Utilities");

ok(grep { $_ eq 'Monkey::Plugin::Mandrill' } @modules,
   "We should find Monkey::Plugin::Bonobo::Utilities");

done_testing;

