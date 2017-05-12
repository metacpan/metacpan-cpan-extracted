#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok("Populous");

my $p = Populous->new(
	classes => [
    'user' => sub { 'User '.(shift).' called '.(shift) },
    {
      does => sub { (shift).' does '.(shift) },
      suicide => sub { $_->delete },
    },
  ],
);

$p->new_user(
  a => "Abraham",
  b => "Betleham",
  c => "Blue shirt",
);

is($p->get_user("a"),'User a called Abraham','user a');
is($p->get_user("b"),'User b called Betleham','user b');
is($p->user( a => does => 'stuff'),'User a called Abraham does stuff','user a does via array');
is($p->user("a")->does('stuff'),'User a called Abraham does stuff','user a does via function');
is($p->user( b => does => 'otherstuff'),'User b called Betleham does otherstuff','user b does via array');
is($p->user("b")->does('otherstuff'),'User b called Betleham does otherstuff','user b does via function');
is($p->user("b")->does('otherstuff'),'User b called Betleham does otherstuff','user b does via function');

$p->user("a")->suicide;
is($p->user("a"),undef,'user a killed himself');

is($p->get_user("c"),"User c called Blue shirt",'user c still alive');

$p->delete_user("c");
is($p->get_user("c"),undef,'user c was killed');

done_testing;
