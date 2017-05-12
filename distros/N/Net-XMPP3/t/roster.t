use lib "t/lib";
use Test::More tests=>75;

BEGIN{ use_ok( "Net::XMPP3" ); }

require "t/mytestlib.pl";

my $debug = new Net::XMPP3::Debug(setdefault=>1,
                                 level=>-1,
                                 file=>"stdout",
                                 header=>"test",
                                );

#------------------------------------------------------------------------------
# Client
#------------------------------------------------------------------------------
my $Client = new Net::XMPP3::Client();
ok( defined($Client), "new()");
isa_ok($Client,"Net::XMPP3::Client");
isa_ok($Client,"Net::XMPP3::Connection");

#------------------------------------------------------------------------------
# Roster
#------------------------------------------------------------------------------
my $Roster = new Net::XMPP3::Roster(connection=>$Client);
ok( defined($Roster), "new()");
isa_ok($Roster,"Net::XMPP3::Roster");

my $jid1 = 'test1@example.com';
my $res1 = "Work";
my $res2 = "Home";

my $jid2 = 'test2@example.com';
my $group1 = 'Test1';
my $group2 = 'Test2';

#------------------------------------------------------------------------------
# Add JIDs to Roster
#------------------------------------------------------------------------------
ok( !$Roster->exists($jid1), "jid1 does not exist");
ok( !$Roster->exists($jid2), "jid2 does not exist");

$Roster->add($jid1);
ok( $Roster->exists($jid1), "jid1 exists");
ok( !$Roster->exists($jid2), "jid2 does not exist");

ok( !$Roster->groupExists($group1), "group1 does not exist");
ok( !$Roster->groupExists($group2), "group2 does not exist");

$Roster->add($jid2,
             ask => "no",
             groups => [ $group1, $group2 ],
             name => "Test",
             subscription => "both",
            );
ok( $Roster->exists($jid1), "jid1 exists");
ok( $Roster->exists($jid2), "jid2 exists");

ok( $Roster->groupExists($group1), "group1 exists");
ok( $Roster->groupExists($group2), "group2 exists");

my @jids = $Roster->jids("all");
is($#jids, 1, "all - two jids");
ok(($jids[0]->GetJID() eq $jid1) || ($jids[1]->GetJID() eq $jid1), "all - jid1 matched");
ok(($jids[0]->GetJID() eq $jid2) || ($jids[1]->GetJID() eq $jid2), "all - jid2 matched");

@jids = $Roster->jids("group",$group1);
is($#jids, 0, "group - $group1 - one jid");
is($jids[0]->GetJID(), $jid2, "group - $group1 - jid2 matched");

@jids = $Roster->jids("group",$group2);
is($#jids, 0, "group - $group2 - one jid");
is($jids[0]->GetJID(), $jid2, "group - $group2 - jid2 matched");

@jids = $Roster->jids("nogroup");
is($#jids, 0, "nogroup - one jid");
is($jids[0]->GetJID(), $jid1, "nogroup - jid1 matched");

my %query = $Roster->query($jid1);
is_deeply( \%query, { }, "jid1 - query");

%query = $Roster->query($jid2);
is_deeply( \%query, { ask=>"no",groups=>[$group1,$group2],name=>"Test",subscription=>"both"}, "jid2 - query");

is( $Roster->query($jid2,"name"), "Test", "jid1 - name == Test");
is( $Roster->query($jid2,"foo"), undef, "jid1 - foo does not exist");

$Roster->store($jid2,"foo","bar");

is( $Roster->query($jid2,"name"), "Test", "jid1 - name == Test");
is( $Roster->query($jid2,"foo"), "bar", "jid1 - foo == bar");

#------------------------------------------------------------------------------
# Simulate presence
#------------------------------------------------------------------------------

ok( !$Roster->online($jid1), "jid1 not online");
ok( !$Roster->online($jid2), "jid2 not online");

$Roster->addResource($jid1, $res1);

ok( $Roster->online($jid1), "jid1 online");
ok( !$Roster->online($jid2), "jid2 not online");

is( $Roster->resource($jid1), $res1, "jid1 resource matches");

$Roster->addResource($jid1, $res2,
                     priority => 100,
                     show => "xa",
                     status => "test",
                    );

ok( $Roster->online($jid1), "jid1 online");
ok( !$Roster->online($jid2), "jid2 not online");

is( $Roster->resource($jid1), $res2, "jid1 resource matches");

my @resources = $Roster->resources($jid1);
is( $#resources, 1, "two resources");

is( $resources[0], $res2, "res2 is highest");
is( $resources[1], $res1, "res1 is lowest");

@resources = $Roster->resources($jid2);
is( $#resources, -1, "no resources");

my %resQuery = $Roster->resourceQuery($jid1,$res1);
is_deeply( \%resQuery, { priority => 0 }, "jid1/res1 - query");

%resQuery = $Roster->resourceQuery($jid1,$res2);
is_deeply( \%resQuery, { priority=>100, show=>"xa", status=>"test"}, "jid1/res2 - query");

is( $Roster->resourceQuery($jid1,$res2,"show"), "xa", "jid2/res2 - show == xa");
is( $Roster->resourceQuery($jid1,$res2,"foo"), undef, "jid2/res2 - foo does not exist");

$Roster->resourceStore($jid1,$res2,"foo","bar");

%resQuery = $Roster->resourceQuery($jid1,$res2);
is_deeply( \%resQuery, { foo=>"bar",priority=>100, show=>"xa", status=>"test"}, "jid1/res2 - query");

is( $Roster->resourceQuery($jid1,$res2,"show"), "xa", "jid2/res2 - show == xa");
is( $Roster->resourceQuery($jid1,$res2,"foo"), "bar", "jid2/res2 - foo == bar");

ok( $Roster->online($jid1), "jid1 online");
ok( !$Roster->online($jid2), "jid2 not online");

$Roster->removeResource($jid1, $res2);

is( $Roster->resource($jid1), $res1, "jid1 resource matches");

@resources = $Roster->resources($jid1);
is( $#resources, 0, "one resource");

is( $resources[0], $res1, "res1 is highest");

ok( $Roster->online($jid1), "jid1 online");
ok( !$Roster->online($jid2), "jid2 not online");

$Roster->removeResource($jid1, $res1);

is( $Roster->resource($jid1), undef, "jid1 no resources");

@resources = $Roster->resources($jid1);
is( $#resources, -1, "no resources");

ok( !$Roster->online($jid1), "jid1 not online");
ok( !$Roster->online($jid2), "jid2 not online");

#-----------------------------------------------------------------------------
# Remove JIDs
#-----------------------------------------------------------------------------

ok( $Roster->exists($jid1), "jid1 exists");
ok( $Roster->exists($jid2), "jid2 exists");

@jids = $Roster->jids("all");
is($#jids, 1, "all - two jids");
ok(($jids[0]->GetJID() eq $jid1) || ($jids[1]->GetJID() eq $jid1), "all - jid1 matched");
ok(($jids[0]->GetJID() eq $jid2) || ($jids[1]->GetJID() eq $jid2), "all - jid2 matched");

$Roster->remove($jid2);

ok( !$Roster->groupExists($group1), "group1 does not exist");
ok( !$Roster->groupExists($group2), "group2 does not exist");

ok( $Roster->exists($jid1), "jid1 exists");
ok( !$Roster->exists($jid2), "jid2 does not exist");

@jids = $Roster->jids("all");
is($#jids, 0, "all - one jid");
is($jids[0]->GetJID(), $jid1, "all - jid1 matched");

$Roster->clear();

ok( !$Roster->exists($jid1), "jid1 does not exist");
ok( !$Roster->exists($jid2), "jid2 does not exist");

@jids = $Roster->jids("all");
is($#jids, -1, "all - no jids");



