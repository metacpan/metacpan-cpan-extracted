#!/usr/bin/perl -wT

# $Id: 41-Bootstrap.t,v 1.2 2003/05/28 14:32:24 unimlo Exp $

use strict;

use Test::More tests => 16;

# Use
use_ok('Net::ACL');
use_ok('Net::ACL::File');
use_ok('Net::ACL::File::IPAccess');
use_ok('Net::ACL::Bootstrap');
use Net::ACL::Rule qw( :action );

# Construction of Bootstrapper
my $proxy = renew Net::ACL::Bootstrap(Name => '42', Type => 'access-list');
ok(ref $proxy eq 'Net::ACL::Bootstrap','Simple construction');

# Construction of the list
my $lists_hr = load Net::ACL::File('access-list 42 permit 127.0.0.1');
my $list = $lists_hr->{'access-list'}->{42};
ok((ref $list) && $list->isa('Net::ACL::File'),'List load');

# Test name and type
ok($proxy->name eq '42','Name of list');
$proxy->name(43);
ok($proxy->name eq '43','Name of list modification');
ok($proxy->type eq 'access-list','Type of list');

# Clone
my $clone = $proxy->clone;
ok($clone->isa('Net::ACL::File'),'Cloning');

# Match
ok($proxy->match('10.0.0.0')    eq ACL_DENY,  'Match deny');
ok($clone->match('127.0.0.1')   eq ACL_PERMIT,'Match permit');

# Query
ok(($proxy->query('127.0.0.1'))[0] eq ACL_PERMIT, 'Query 1 (permit)');
ok(($proxy->query('127.0.0.1'))[1] eq '127.0.0.1','Query 2 (unmodified)');
ok(($proxy->query('127.0.0.2'  ))[0] eq ACL_DENY, 'Query 3 (deny)');
ok(! defined(($proxy->query('128.0.0.0'))[1]),    'Query 4 (deny undefined)');

__END__
