#!perl -w

use strict;
use Test::More tests => 25;
use DateTime;
use_ok("Net::Gnip::Activity");
use_ok("Net::Gnip::Activity::Payload");

my $activity;
my $uid       = time.$$.rand();
my $action    = 'update';
my $at        = DateTime->now->epoch;
my $actor     = 'foo';
eval { $activity = Net::Gnip::Activity->new };
ok($@, "Caught error");
is($activity, undef, "No activity returned");
ok($activity = Net::Gnip::Activity->new($action, $actor, _no_dt => 1), "Created a activity");
ok($activity->at <= DateTime->now->epoch,                              "Default 'at' set");
ok($activity = Net::Gnip::Activity->new($action, $actor, 'at' => $at, _no_dt => 1), "Created a activity");
is($activity->at,     $at,     "Got same at");
is($activity->action, $action, "Got same action");
is($activity->actor,  $actor,  "Got the same actor");

my $payload;
my $body    = "test body";
ok($payload = Net::Gnip::Activity::Payload->new($body), "Created payload");
ok($activity->payload($payload),                        "Added payload");
is($activity->payload->body, $body,                     "Got same body back");



$at = DateTime->now()->add( months => 1)->epoch;
ok($activity->at($at), "Set at");
is($activity->at, $at, "Got same at back again");

my $at_string = "2008-10-19T20:46:01.000Z";
$at           = eval {  Net::Gnip::Activity->_handle_datetime($at_string)->epoch };
ok(!$@, "Parsed at string");
ok($activity->at($at_string), "Passed at string in");
isnt($activity->at, $at,    , "Got unparsed at back - don't do that!");

my $xml = '<activity at="'.$at_string.'" actor="joe" action="update"><payload><body>'.$body.'</body></payload></activity>';
ok($activity = $activity->parse($xml), "Parsed xml");

ok($xml = $activity->as_xml, "Generated xml");

ok($activity = Net::Gnip::Activity->parse($xml, _no_dt => 1), "Parsed xml again");
is($activity->at,     $at,          "Got correct at from parse");
is($activity->actor,  'joe',        "Got correct actor from parse");
is($activity->action, 'update',     "Got correct action from parse");
is($activity->payload->body, $body, "Got same body back");


