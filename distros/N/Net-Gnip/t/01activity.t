#!perl -w

use strict;
use Test::More tests => 25;
use DateTime;
use_ok("Net::Gnip::Activity");
use_ok("Net::Gnip::Activity::Payload");

my $activity;
my $action    = 'update';
my $at        = DateTime->now;
my $actor     = 'foo';
eval { $activity = Net::Gnip::Activity->new };
ok($@, "Caught error");
is($activity, undef, "No activity returned");
ok($activity = Net::Gnip::Activity->new($action, $actor, ), "Created a activity");
ok($activity->at <= DateTime->now,                          "Default 'at' set");
ok($activity = Net::Gnip::Activity->new($action, $actor, 'at' => $at), "Created a activity");
is($activity->at,     $at,     "Got same at");
is($activity->action, $action, "Got same action");
is($activity->actor,  $actor,  "Got the same actor");

my $payload;
my $body    = "test body";
ok($payload = Net::Gnip::Activity::Payload->new($body), "Created payload");
ok($activity->payload($payload),                        "Added payload");
is($activity->payload->body, $body,                     "Got same body back");

$at = DateTime->now()->add( months => 1);
ok($activity->at($at), "Set at");
is($activity->at, $at, "Got same at back again");

my $at_string = "2008-10-19T20:46:01.000Z";
$at           = eval {  Net::Gnip::Activity->_handle_datetime($at_string) };
ok(!$@, "Parsed at string");
ok($activity->at($at_string), "Passed at string in");
is($activity->at, $at,      , "Got correctly parsed at back");

my $xml = '<activity at="2008-10-19T20:46:01.000Z" actor="joe" action="update"><payload><body>'.$body.'</body></payload></activity>';
ok($activity = $activity->parse($xml), "Parsed xml");

ok($xml = $activity->as_xml, "Generated xml");

ok($activity = Net::Gnip::Activity->parse($xml), "Parsed xml again");
is($activity->at,     $at,      "Got correct at from parse");
is($activity->actor,  'joe',    "Got correct actor from parse");
is($activity->action, 'update', "Got correct action from parse");
is($activity->payload->body, $body, "Got same body back");


