use Test::Simple 'no_plan';
use lib './lib';
use strict;
use warnings;
use News::Pan::Server;
use Cwd;

my $s = new News::Pan::Server({ abs_path => cwd().'/t/.pan/astraweb' });

ok($s);

my $groups = $s->groups_subscribed;
ok($groups);
ok(scalar @$groups == 3, '3 groups');



my $groups_binaries = $s->groups_subscribed_binaries;
ok($groups_binaries);
ok(scalar @$groups_binaries == 2 , '2 groups binaries');













