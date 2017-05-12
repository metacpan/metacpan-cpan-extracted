#!/usr/bin/perl -wT

# $Id: 10-MatchIP.t,v 1.2 2003/05/27 22:42:10 unimlo Exp $

use strict;

use Test::More tests => 8;

# Use
use_ok('Net::Netmask');
use_ok('Net::ACL::Match::IP');
use_ok('Net::ACL::Rule');
use Net::ACL::Rule qw( :rc );

# Construction
my $match = new Net::ACL::Match::IP(0,'10.0.0.0/8');
ok(ref $match eq 'Net::ACL::Match::IP','Normal construction');
ok($match->isa('Net::ACL::Match'),     'Inheritence');

ok($match->match('10.0.0.0')   eq ACL_MATCH,  'Match 1');
ok($match->match('10.255.0.0') eq ACL_MATCH,  'Match 2');
ok($match->match('127.0.0.1')  eq ACL_NOMATCH,'Match 3');

__END__
