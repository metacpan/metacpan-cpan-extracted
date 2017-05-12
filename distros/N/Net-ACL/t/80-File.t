#!/usr/bin/perl -wT

# $Id: 80-File.t,v 1.10 2003/06/06 19:52:05 unimlo Exp $

use strict;

use Test::More tests => 171;

eval <<USES;
use Net::BGP::NLRI qw( :origin );
use Net::BGP::Peer;
use Net::ACL::File::RouteMap;
USES

my $hasbgp = $@ ? 0 : 1;

# Use
use_ok('Cisco::Reconfig');
use_ok('Net::ACL');
use_ok('Net::ACL::File');
use_ok('Net::ACL::File::Standard');
use_ok('Net::ACL::File::IPAccess');
use_ok('Net::ACL::File::IPAccessExt');
use_ok('Net::ACL::File::Community');
use_ok('Net::ACL::File::ASPath');
use_ok('Net::ACL::File::Prefix');
use Net::ACL::Rule qw( :action );

my $myconf = <<CONFDATA;
! Access-lists
access-list 10 permit 10.20.30.0 0.0.0.255
access-list 10 permit 10.30.0.0 0.0.255.255
access-list 12 deny 10.0.0.0 0.255.255.255
access-list 12 permit any
! Access-list extended
ip access-list extended like10
 permit ip any 10.20.30.0 0.0.0.255
 permit ip any 10.30.0.0 0.0.255.255
ip access-list extended like12
 deny ip any 10.0.0.0 0.255.255.255
 permit ip any any
! Community-lists
ip community-list 1 permit 65001:1
ip community-list 42 deny 65001:1
ip community-list 42 permit
! Prefix-lists
ip prefix-list ournet seq 10 permit 10.0.0.0/8
ip prefix-list ournet seq 20 permit 192.168.0.0/16
! AS Path-lists
ip as-path access-list 1 permit .*
ip as-path access-list 2 permit ^\$
ip as-path access-list 55 permit ^65001_65002
CONFDATA

$myconf .= <<CONFDATA if $hasbgp;
! Route-maps
route-map bgp-in deny 10
 match ip address prefix-list ournet
route-map bgp-in permit 20
 set community 65001:800
 set aspath prepend 65001
route-map bgp-out permit 10
 match ip address prefix-list ournet
 match ip next-hop prefix-list ournet
 set aspath prepend 65001
route-map bgp-out deny 20
route-map prepend permit 10
 set aspath prepend 65001
CONFDATA

my $lists = load Net::ACL::File($myconf);

my %myconf;
foreach my $line (split(/\n/,$myconf))
 {
  next if $line =~ /^!/;
  $myconf{$line} ||= 0;
  $myconf{$line} += 1;
 };

my %i;
foreach my $pair (
# Format:
#  [list-type, list-name, [ rc, [input],[output]]]
#
	['access-list','10',
		[ACL_PERMIT,['10.20.30.40']],
		[ACL_PERMIT,['10.30.30.40']],
		[ACL_DENY,  ['11.12.13.13']]
		],
	['access-list','12',
		[ACL_DENY,  ['10.20.30.40']],
		[ACL_PERMIT,['11.21.31.41']]
		],
	['extended-access-list','like10',
		[ACL_PERMIT,['ip','192.168.1.1','10.20.30.40']],
		[ACL_PERMIT,['ip','192.168.1.1','10.30.30.40']],
		[ACL_DENY,  ['ip','192.168.1.1','11.12.13.13']]
		],
	['extended-access-list','like12',
		[ACL_DENY,  ['ip','192.168.1.1','10.20.30.40']],
		[ACL_PERMIT,['ip','192.168.1.1','11.21.31.41']]
		],
	['community-list','1',
		[ACL_PERMIT,[['65001:1']]],
		[ACL_DENY,  [['65001:2']]]
		],
	['community-list','42',
		[ACL_PERMIT,[['65001:2']]],
		[ACL_DENY,  [['65001:1']]]
		],
	['as-path-list','1'],
	['as-path-list','2'],
	['as-path-list','55'],
	['prefix-list','ournet'],
	['route-map','prepend'],
	['route-map','bgp-in'],
	['route-map','bgp-out']
	)
 {
  my ($type,$name,@tests) = @{$pair};
  next unless $type ne 'route-map' || $hasbgp;
  my $list1 = $lists->{$type}->{$name};
  ok(defined $list1,"Got something for $type $name");
  next unless defined $list1;
  ok($list1->isa('Net::ACL::File'),"Load $type $name");
  ok($list1->name eq $name,"Name $type $name");
  ok($list1->type eq $type,"Type $type $name");
  my $list2 = renew Net::ACL(
	Name => $name,
	Type => $type
	);
  ok($list2->isa('Net::ACL'),"Renew $type $name");
  my $conf = $list2->asconfig;
  #print "---CUT---\n${conf}---CUT---\n";
  #use Data::Dumper; warn Dumper($list2) unless $conf ne '';
  $list2->name(undef);
  ok(! defined $list2->name,"Name removed for $type $name");
  foreach my $line (split(/\n/,$conf))
   {
    next if $line =~ /^!/;
    ok(defined $myconf{$line},'Got correct configline: ' . $line);
    if (defined $myconf{$line})
     {
      $myconf{$line} -= 1;
      delete $myconf{$line} if $myconf{$line} == 0;
     };
   };
  my $newhash = load Net::ACL::File($conf);
  my $newlist = $newhash->{$type}->{$name};
  ok(defined $newlist,"Got something back for $type $name");
  next unless defined $newlist;
  ok($newlist->asconfig eq $conf,"Load(asconfig) $type $name");
  $newhash = undef;
  $newlist = undef;
  ok($list2->name($name) eq $name,"Changed name back $type $name");
  my $i = 0;
  foreach my $test (@tests)
   {
    my ($rc,$input,$output) = @{$test};
    $i+=1;
    ok($list2->match(@{$input}) == $rc,"Match test $i for $type $name");
    next unless defined $output;
    my ($rc2,@res) = $list2->query(@{$input});
    ok($rc2 == $rc,"Query test result code $i for $type $name");
    ok(&mycompare($output,\@res),"Query test output $i for $type $name");
   };
 };

SKIP: {
skip('No recent Net::BGP::NLRI',39) unless $hasbgp;
}

# Got it all?
my $noleft = scalar (keys %myconf);
ok($noleft == 0,"All config lines regenerated ($noleft left)");
diag(map { "Missing: $_\n" } sort keys %myconf) if $noleft;


# Check operation of other lists....

sub mycompare
{
 fail('Compare not implemented!!!');
}
__END__
