#!/usr/bin/perl -wT

# $Id: 50-RouteMap.t,v 1.8 2003/06/06 19:28:40 unimlo Exp $

use strict;


eval <<USES;
use Net::BGP::NLRI qw( :origin );
use Net::BGP::Peer;
USES

if ($@)
 {
  eval "use Test::More skip_all => 'No resent Net::BGP installed';";
  exit;
 }
else
 {
  eval "use Test::More tests => 89;";
 };

# Use
use_ok('Net::ACL');
use_ok('Net::ACL::File');
use_ok('Net::ACL::File::ASPath');
use_ok('Net::ACL::File::Community');
use_ok('Net::ACL::File::IPAccess');
use_ok('Net::ACL::File::Prefix');
use_ok('Net::ACL::RouteMapRule');
use Net::ACL::Rule qw( :rc :action );

# Helpers
my $helpers = load Net::ACL::File(<<CONF);
ip as-path access-list 1 permit ^65001
ip as-path access-list 3 permit ^65001_65002
ip community-list 2 permit 65001:50
ip community-list 4 permit 65001:1 65001:2
ip prefix-list 5 permit 10.20.30.0/24
access-list 6 permit 10.0.0.2
CONF

# Construction
my $permit = new Net::ACL::RouteMapRule(Action => ACL_PERMIT);
my $deny = new Net::ACL::RouteMapRule(Action => ACL_DENY);
my $change = new Net::ACL::RouteMapRule(Action => ACL_DENY);

ok($permit->isa('Net::ACL::RouteMapRule'),'Permit construction 1');
ok($permit->isa('Net::ACL::Rule'),        'Permit construction 2');
ok($permit->action == ACL_PERMIT,         'Action permit value');
ok($permit->action_str eq 'permit',       'Action permit string');
ok($deny->isa('Net::ACL::RouteMapRule'),  'Deny construction 1');
ok($deny->isa('Net::ACL::Rule'),          'Deny construction 2');
ok($deny->action == ACL_DENY,             'Action deny value');
ok($deny->action_str eq 'deny',           'Action deny string');
$change->action(ACL_PERMIT);
ok($change->action == ACL_PERMIT,         'Action modify value');
$change->action_str('deny');
ok($change->action == ACL_DENY,           'Action modify string 1');
$change->action_str('pERMit');
ok($change->action == ACL_PERMIT,         'Action modify string 2');

my $aspath_comm = new Net::ACL::RouteMapRule(
	Action	=> ACL_CONTINUE,
	Match	=> {
		ASPath		=> [ 1 ]
		},
	Set	=> {
		ASPath		=> "(65001 65002)",
		Community	=> [ qw(65001:200 65001:300) ]
		}
	);
ok($aspath_comm->isa('Net::ACL::RouteMapRule'),'Complex construction 1');

my $deny_comm = new Net::ACL::RouteMapRule(
        Action  => ACL_DENY,
	Match	=> {
		Community	=> [ 2 ]
		}
	);
ok($deny_comm->isa('Net::ACL::RouteMapRule'),'Complex construction 2');

my $loc10to20 = new Net::ACL::RouteMapRule(
	Action	=> ACL_PERMIT,
	Match	=> {
		LocalPref =>	10
		},
	Set	=> {
		LocalPref =>	20
		}
	);
ok($loc10to20->isa('Net::ACL::RouteMapRule'),'Complex construction 3');
my $all = new Net::ACL::RouteMapRule(
	Action	=> ACL_PERMIT,
	Match	=> {
		ASPath		=> [ 3 ],
		Community	=> [ 4 ],
		MED		=> 20,
		Prefix		=> [ 5 ],
		Nexthop		=> [ 6 ]
		},
	Set	=> {
		Prepend		=> 65010,
		Community	=> [ qw(65001:20) ],
		MED		=> 50,
		Nexthop		=> '10.0.0.1'
		}
	);
ok($all->isa('Net::ACL::RouteMapRule'),'Complex construction 4');

my @rules = ($aspath_comm, $deny_comm, $loc10to20, $all);
		
my $peer = new Net::BGP::Peer(
	ThisID	=> '10.1.1.1',
	PeerID	=> '!0.2.2.2'
	);
ok(ref $peer eq 'Net::BGP::Peer','Peer construction');
my $nlri1 = new Net::BGP::NLRI(
	ASPath => 65000,
	Communities => [ '65001:1' ],
	LocalPref => 15
	);
my $nlri2 = new Net::BGP::NLRI(
	ASPath          => 65001,
	Communities     => [ '65001:50' ],
	LocalPref       => 30,
	Aggregator      => [ 64512, '10.0.0.1' ],
        AtomicAggregate => 1,
        MED             => 200,
        NextHop         => '10.0.0.1',
        Origin          => &Net::BGP::NLRI::INCOMPLETE
	);
my $nlri2a = new Net::BGP::NLRI(
	ASPath		=> "(65001 65002) 65001",
	Communities	=> [ qw(65001:50 65001:200 65001:300) ],
	LocalPref	=> 30,
	Aggregator      => [ 64512, '10.0.0.1' ],
        AtomicAggregate => 1,
        MED             => 200,
        NextHop         => '10.0.0.1',
        Origin          => &Net::BGP::NLRI::INCOMPLETE
	);
my $nlri3 = new Net::BGP::NLRI(
        ASPath          => "65001 65002",
	Communities	=> [ qw(65001:1 65001:2) ],
        MED             => 20,
        Nexthop         => '10.0.0.2',
	LocalPref	=> 10
	);
my $nlri3a = new Net::BGP::NLRI(
        ASPath          => "(65001 65002) 65001 65002",
	Communities	=> [ qw(65001:1 65001:2 65001:200 65001:300) ],
        MED             => 20,
        Nexthop         => '10.0.0.2',
	LocalPref	=> 10
	);
my $nlri3b = new Net::BGP::NLRI(
        ASPath          => "65001 65002",
	Communities	=> [ qw(65001:1 65001:2) ],
        MED             => 20,
        Nexthop         => '10.0.0.2',
	LocalPref	=> 20
	);
my $nlri3c = new Net::BGP::NLRI(
        ASPath          => "65010 65001 65002",
	Communities	=> [ qw(65001:1 65001:2 65001:20) ],
        MED             => 50,
        Nexthop         => '10.0.0.1',
	LocalPref	=> 10
	);

my @tests = (
	[$nlri1,
		[ACL_NOMATCH,ACL_CONTINUE,$nlri1],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri1],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri1],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri1]
	],
	[$nlri2,
		[ACL_MATCH  ,ACL_CONTINUE,$nlri2a],
		[ACL_MATCH  ,ACL_DENY    ,undef],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri2],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri2]
	],
	[$nlri3,
		[ACL_MATCH  ,ACL_CONTINUE,$nlri3a],
		[ACL_NOMATCH,ACL_CONTINUE,$nlri3],
		[ACL_MATCH  ,ACL_PERMIT  ,$nlri3b],
		[ACL_MATCH  ,ACL_PERMIT  ,$nlri3c]
	]
	);

my $prefix = '10.20.30.0/24';

my $tno = 0;
foreach my $testpair (@tests)
 {
  my ($nlri,@subtests) = @{$testpair};
  $tno++;
  ok($nlri->isa('Net::BGP::NLRI'),"NLRI Construction $tno");
  my $nlri2 = $all->_list2nlri($all->_nlri2list($nlri));
  ok($nlri eq $nlri2,"NLRI to list and back $tno");
  my $no = 0;
  foreach my $test (@subtests)
   {
    my ($match,$query,$querynlri) = @{$test};
    my $rule = $rules[$no++];
    ok($rule->match($prefix,$nlri,$peer) == $match,"Match $tno - $no");
    my ($rc,$newprefix,$newnlri,$newpeer) = $rule->query($prefix,$nlri,$peer);
    ok($rc == $query,"Query RC $tno - $no");
    ok((! defined $newnlri && ! defined $querynlri)
      || ($newnlri eq $querynlri),"Query Data $tno - $no");
    ok((! defined $querynlri)
      || ($newprefix eq $prefix),"Query Prefix $tno - $no");
    ok((! defined $querynlri)
      || ($peer eq $newpeer),"Query Peer $tno - $no");
   };
 };

