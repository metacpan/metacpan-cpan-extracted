#!/usr/bin/perl -wT

# $Id: 11-MatchPrefix.t,v 1.1 2003/05/28 14:32:56 unimlo Exp $

use strict;

use Test::More tests => 27;

# Use
use_ok('Net::Netmask');
use_ok('Net::ACL::Match::Prefix');
use_ok('Net::ACL::Rule');
use Net::ACL::Rule qw( :rc );

# Construction
my $norm = new Net::ACL::Match::Prefix(0,'10.0.0.0/8');

ok(ref $norm eq 'Net::ACL::Match::Prefix','Normal construction');
ok($norm->isa('Net::ACL::Match'),     'Inheritence');

my $ge24 = new Net::ACL::Match::Prefix(0,'10.0.0.0/8 ge 24');
ok(ref $ge24 eq 'Net::ACL::Match::Prefix','Construction with ge');
ok($ge24->isa('Net::ACL::Match'),     'Inheritence of ge');

my $le24 = new Net::ACL::Match::Prefix(0,'10.0.0.0/8 le 24');
ok(ref $le24 eq 'Net::ACL::Match::Prefix','Construction with le');
ok($le24->isa('Net::ACL::Match'),     'Inheritence of le');

my $arg3 = new Net::ACL::Match::Prefix(2,'10.0.0.0/8 le 24');
ok(ref $arg3 eq 'Net::ACL::Match::Prefix','Construction with third');
ok($arg3->isa('Net::ACL::Match'),     'Inheritence with thids');

# Matching
ok($norm->match('10.0.0.0/8')   eq ACL_MATCH,  'Match normal 1');
ok($norm->match('10.1.0.0/16')  eq ACL_NOMATCH,'Match normal 2');
ok($norm->match('10.1.0.0/28')  eq ACL_NOMATCH,'Match normal 3');
ok($norm->match('127.0.0.0/8')  eq ACL_NOMATCH,'Match normal 4');

ok($ge24->match('10.0.0.0/8')   eq ACL_NOMATCH,'Match ge 1');
ok($ge24->match('10.1.0.0/16')  eq ACL_NOMATCH,'Match ge 2');
ok($ge24->match('10.1.0.0/28')  eq ACL_MATCH,  'Match ge 3');
ok($ge24->match('127.0.0.0/8')  eq ACL_NOMATCH,'Match ge 4');

ok($le24->match('10.0.0.0/8')   eq ACL_MATCH,  'Match le 1');
ok($le24->match('10.1.0.0/16')  eq ACL_MATCH,  'Match le 2');
ok($le24->match('10.1.0.0/28')  eq ACL_NOMATCH,'Match le 3');
ok($le24->match('127.0.0.0/8')  eq ACL_NOMATCH,'Match le 4');

ok($arg3->match(1,2,'10.0.0.0/8')   eq ACL_MATCH,  'Match third 1');
ok($arg3->match(1,2,'10.1.0.0/16')  eq ACL_MATCH,  'Match third 2');
ok($arg3->match(1,2,'10.1.0.0/28')  eq ACL_NOMATCH,'Match third 3');
ok($arg3->match(1,2,'127.0.0.0/8')  eq ACL_NOMATCH,'Match third 4');

__END__
