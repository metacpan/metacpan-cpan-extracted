use strict;
use warnings;
use Test::More tests => 17;
use t::useragent;

use_ok('Net::Plazes::Activity');

my $ua = t::useragent->new({
			    is_success => 1,
			   });

{
  my $a = Net::Plazes::Activity->new();
  isa_ok($a, 'Net::Plazes::Activity');
}

{
  my $a = Net::Plazes::Activity->new({
				      useragent => $ua,
				      id        => 6362819,
				     });
  is($a->device(),  'plazer', 'activity.device');
  is($a->status(),  q[],      'activity.status');
  is($a->user_id(), 245211,   'activity.user_id');
}

{
  my $a = Net::Plazes::Activity->new({
				      useragent => $ua,
				     });
  my $activities = $a->activities();
  isa_ok($activities, 'ARRAY', 'activity.activities');
  is((scalar @{$activities}), 50, 'activity.activities.length');

  isa_ok($activities->[0], 'Net::Plazes::Activity', 'activities.user[0]');
  is($activities->[0]->id(), 6362837, 'activities.user[0] id');

  isa_ok($activities->[-1], 'Net::Plazes::Activity', 'activities.user[-1]');
  is($activities->[-1]->user_id(), 1817, 'activities.user[-1] user_id');
}

{
  my $a = Net::Plazes::Activity->new({
				      useragent => $ua,
				      id        => 6362819,
				     });
  my $user = $a->user();
  isa_ok($user, 'Net::Plazes::User', 'activity.user');
  is($user->id(),         245211, 'activity.user id');
  is($user->full_name(), 'Morris Packer', 'activity.user full_name');

  my $plaze = $a->plaze();
  isa_ok($plaze, 'Net::Plazes::Plaze', 'activity.plaze');
  is($plaze->id(), 131865, 'activity.plaze id');
  is($plaze->name(), 'Home', 'activity.plaze name');
}
