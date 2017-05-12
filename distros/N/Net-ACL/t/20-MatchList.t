#!/usr/bin/perl -wT

# $Id: 20-MatchList.t,v 1.2 2003/05/27 23:19:24 unimlo Exp $

use strict;

use Test::More tests => 17;

# Use
use_ok('Net::ACL::Match::List');
use_ok('Net::ACL::Match::IP');
use_ok('Net::ACL');
use_ok('Net::ACL::Rule');
use Net::ACL::Rule qw( :action :rc );

# Construction - List 1
my $matchip1 = new Net::ACL::Match::IP(0,'10.0.0.0/8');
my $rule1 = new Net::ACL::Rule(
	Action	=> ACL_PERMIT,
	Match	=> $matchip1
	);
my $list1 = new Net::ACL(
	Name	=> 42,
	Type	=> 'ip-list',
	Rule	=> $rule1
	);

# Construction - List 2
my $matchip2 = new Net::ACL::Match::IP(0,'10.10.0.0/16');
my $rule2 = new Net::ACL::Rule(
	Action	=> ACL_PERMIT,
	Match	=> $matchip2
	);
my $list2 = new Net::ACL(
	Name	=> 43,
	Type	=> 'ip-list',
	Rule	=> $rule2
	);

# The real construction
my $match1 = new Net::ACL::Match::List(0,$list1);
ok(ref $match1 eq 'Net::ACL::Match::List','Construction 1');
ok($match1->isa('Net::ACL::Match'),'Inheritence');

my $match2 = new Net::ACL::Match::List(0, $list1, $list2 );
ok(ref $match2 eq 'Net::ACL::Match::List','Construction 2');

my $match3 = new Net::ACL::Match::List(0, $list1, {
	Name	=> 43,
	Type	=> 'ip-list'
	});
ok(ref $match3 eq 'Net::ACL::Match::List','Construction 3');

ok($match1->match('10.0.0.0')   eq ACL_MATCH,  'Match 1a');
ok($match1->match('10.255.0.0') eq ACL_MATCH,  'Match 1b');
ok($match1->match('127.0.0.1')  eq ACL_NOMATCH,'Match 1c');

ok($match2->match('10.0.0.0')   eq ACL_NOMATCH,'Match 2a');
ok($match2->match('10.10.10.0') eq ACL_MATCH,  'Match 2b');
ok($match2->match('127.0.0.1')  eq ACL_NOMATCH,'Match 2c');

ok($match3->match('10.0.0.0')   eq ACL_NOMATCH,'Match 3a');
ok($match3->match('10.10.10.0') eq ACL_MATCH,  'Match 3b');
ok($match3->match('127.0.0.1')  eq ACL_NOMATCH,'Match 3c');

__END__
