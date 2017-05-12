use strict;
use warnings;

use lib qw( ../lib t/lib lib);

use MyApp;

use Test::More;
END { done_testing(); }

use Test::Mojo;

use_ok('MyApp');

my $t = Test::Mojo->new(MyApp->new);

ok($t,'MyApp new');

$t->ua->max_redirects(3);

subtest 'serverinfo' => sub {
  $t->get_ok('/serverinfo')->status_is(200);
};

subtest '/' => sub {
  $t->get_ok('/')->status_is(200);
};

