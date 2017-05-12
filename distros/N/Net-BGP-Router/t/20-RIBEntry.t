#!/usr/bin/perl -wT

# $Id: 20-RIBEntry.t,v 1.1 2003/06/01 23:40:12 unimlo Exp $

use strict;
use warnings;

use Test::More tests => 29;

# Use
use_ok('Net::ACL::File');
use_ok('Net::ACL::File::RouteMap');
use_ok('Net::BGP::Peer');
use_ok('Net::BGP::NLRI');
use_ok('Net::BGP::Policy');
use_ok('Net::BGP::RIBEntry');

# Construction
my $empty = new Net::BGP::RIBEntry;
ok(ref $empty eq 'Net::BGP::RIBEntry','Simple construction');
my $data = new Net::BGP::RIBEntry(
	Prefix		=>	'10.0.0.0/8'
	);
ok(ref $data eq 'Net::BGP::RIBEntry','Complex construction');

# Copying
my $clone1 = clone Net::BGP::RIBEntry($data);
ok(ref $clone1 eq 'Net::BGP::RIBEntry','Clone construction');
my $clone = $clone1->clone;
ok(ref $clone eq 'Net::BGP::RIBEntry','Cloning');

# Prefix
ok($clone->prefix eq '10.0.0.0/8','Accessor: Prefix');
$clone->prefix('10.0.0.0/16');
ok($clone->prefix eq '10.0.0.0/16','Accessor: Prefix modifyer');

# Setup peers, NLRIs, ACL and Policy
my $nlri1 = new Net::BGP::NLRI(
	LocalPref	=>	10
	);
my $nlri2 = new Net::BGP::NLRI(
	LocalPref	=>	20
	);
my $nlri3 = new Net::BGP::NLRI(
	LocalPref	=>	30
	);
my $nlri4 = new Net::BGP::NLRI(
	LocalPref	=>	25
	);
my $peer1 = new Net::BGP::Peer();
my $peer2 = new Net::BGP::Peer();
my $peer3 = new Net::BGP::Peer();
my $helpers = load Net::ACL::File(<<CONF);
route-map map-in permit 10
 match localpreference 10
 set localpreference 30
route-map map-in permit 20
route-map map-out-2 permit 10
 match localpreference 30
 set localpreference 25
route-map map-out-2 permit 20
route-map map-out-3 permit 10
CONF
$helpers = $helpers->{'route-map'};
my $policy = new Net::BGP::Policy();
$policy->set($peer1,'in',$helpers->{'map-in'});
$policy->set($peer2,'in',$helpers->{'map-in'});
$policy->set($peer2,'out',$helpers->{'map-out-2'});
$policy->set($peer3,'out',$helpers->{'map-out-3'});

# Update In
ok(ref $clone->update_in($peer1,$nlri1) eq 'Net::BGP::RIBEntry','Accessor: Update IN');
$clone->update_in($peer2,$nlri2);

# In
ok($clone->in->{$peer1} eq $nlri1,'Accessor: In 1');
ok($clone->in->{$peer2} eq $nlri2,'Accessor: In 2');

# Update local
ok(  $clone->update_local($policy),'Accessor: Update local 1');
ok(! $clone->update_local($policy),'Accessor: Update local 2');

# Local
ok($clone->local eq $nlri3,'Accessor: Local');

# Update Out
my $changes_hr = $clone->update_out($policy);
ok(! exists $changes_hr->{$peer1},'Accessor: Update out 1');
ok($changes_hr->{$peer2} eq $nlri4,'Accessor: Update out 2');
ok($changes_hr->{$peer3} eq $nlri3,'Accessor: Update out 3');
$changes_hr = $clone->update_out($policy);
ok(! exists $changes_hr->{$peer1},'Accessor: Update out 4');
ok(! exists $changes_hr->{$peer2},'Accessor: Update out 5');
ok(! exists $changes_hr->{$peer3},'Accessor: Update out 6');

# Out
ok(! exists $clone->out->{$peer1},'Accessor: Out 1');
ok($clone->out->{$peer2} eq $nlri4,'Accessor: Out 2');
ok($clone->out->{$peer3} eq $nlri3,'Accessor: Out 3');

# As string
my $str = $clone->asstring;
ok(! ref $str,'Accessor: As string 1');
ok($str !~ /=HASH\(0x/,'Accessor: As string 2');

# Handle changes is hard to test! - And hence skiped!

__END__
