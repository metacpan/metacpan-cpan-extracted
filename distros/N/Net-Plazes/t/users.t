use strict;
use warnings;
use Test::More tests => 14;
use t::useragent;

use_ok('Net::Plazes::User');

my $ua = t::useragent->new({
                            is_success => 1,
                           });

{
  my $u = Net::Plazes::User->new();
  isa_ok($u, 'Net::Plazes::User');
}

{
  my $u = Net::Plazes::User->new({
				  useragent => $ua,
				  id        => 263471,
				 });
  is($u->full_name(), q[]);
  is($u->name(), 'erox');
  is($u->avatar_url(), q[]);
  is($u->created_at(), '2008-07-28T12:41:06Z');
}

{
  my $u = Net::Plazes::User->new({
				  useragent => $ua,
				 });
  my $users = $u->users();
  isa_ok($users, 'ARRAY');
  isa_ok($users->[0], 'Net::Plazes::User');
  is((scalar @{$users}), 50, 'users.length');
  is($users->[0]->id(), 262799, 'users[0].id');
}

{
  my $u = Net::Plazes::User->new({
				  useragent => $ua,
				  id        => 266,
				 });
  my $activities = $u->activities();
  isa_ok($activities, 'ARRAY', 'user.activities');
  is((scalar @{$activities}), 100, 'user.activities.length');
  isa_ok($activities->[0], 'Net::Plazes::Activity', 'user.activities[0]');
  is($activities->[0]->device(), 'web', 'user.activites[0].device');
}

