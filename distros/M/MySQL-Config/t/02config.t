#!/usr/bin/perl
# vim: set ft=perl:

use strict;

use Cwd;
use File::Spec;
use MySQL::Config qw(load_defaults parse_defaults);
use Test::More tests => 19;

use_ok("MySQL::Config");
use_ok("MySQL::Config", qw(load_defaults parse_defaults));

$MySQL::Config::GLOBAL_CNF = File::Spec->catfile(cwd, qw(t my.cnf));

my @groups = qw(foo frobniz);
my $count = 0;
my @argv = ();

load_defaults "my", \@groups, \$count, \@argv;
@argv = sort @argv;

# Got right number of elements
is($count, 5, "Correct number of elements in \\\$count");

# same test, basically
is(scalar @argv, 5, "Correct number of elements in \@argv");

is($argv[0], '--bar=baz', '--bar=baz (name = "my")');
is($argv[1], '--hehe=haha', '--hehe=haha (name = "my")');
is($argv[2], '--my-foot-hurts=1', '--my-foot-hurts=1 (name = "my")');
is($argv[3], '--quux="hoopy frood"', '--quux="hoopy frood" (name = "my")');
is($argv[4], '--string="I said, \"Hello!\""', '--string="I said, \"Hello!\"" (name = "my")');

my %ini = parse_defaults "my", [ qw(foo frobniz) ];

is($ini{'bar'}, 'baz', '$ini{"bar"} = "baz" (name = "my")');
is($ini{'hehe'}, 'haha', '$ini{"hehe"} = "haha" (name = "my")');
is($ini{'quux'}, '"hoopy frood"', '$ini{"quux"} = q("hoopy frood") (name = "my")');
is($ini{'my-foot-hurts'}, 1, '$ini{"my-foot-hurts"} = 1 (name = "my")');
is($ini{'string'}, '"I said, \"Hello!\""', '"I said, \"Hello!\"" (name = "my")');

%ini = parse_defaults "testing", [ qw(foo frobniz) ];

is($ini{'bar'}, 'baz', '$ini{"bar"} = "baz" (name = "testing")');
is($ini{'hehe'}, 'haha', '$ini{"hehe"} = "haha" (name = "testing")');
is($ini{'quux'}, '"hoopy frood"', '$ini{"quux"} = q("hoopy frood") (name = "testing")');
is($ini{'my-foot-hurts'}, 1, '$ini{"my-foot-hurts"} = 1 (name = "testing")');
is($ini{'string'}, '"I said, \"Hello!\""', '$ini{"string"} = "I said, \"Hello!\"" (name = "testing")');
