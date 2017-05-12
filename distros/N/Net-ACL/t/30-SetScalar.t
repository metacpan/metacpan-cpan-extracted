#!/usr/bin/perl -wT

# $Id: 30-SetScalar.t,v 1.2 2003/05/27 23:41:57 unimlo Exp $

use strict;

use Test::More tests => 17;

# Use
use_ok('Net::ACL::Set::Scalar');
use_ok('Net::ACL::Rule');
use Net::ACL::Rule qw( :rc );

# Construction
my $set1 = new Net::ACL::Set::Scalar(0,42);
ok(ref $set1 eq 'Net::ACL::Set::Scalar','Construction 1');
ok($set1->isa('Net::ACL::Set'),'Inheritence');

my $set2 = new Net::ACL::Set::Scalar(1,42);
ok(ref $set2 eq 'Net::ACL::Set::Scalar','Construction 2');

my $set3 = new Net::ACL::Set::Scalar(0,[41,42]);
ok(ref $set3 eq 'Net::ACL::Set::Scalar','Construction 4');

ok(($set1->set(10,20,30))[0] eq 42,  'Set 1a');
ok(($set1->set(10,20,30))[1] eq 20,  'Set 1b');
ok(($set1->set(10,20,30))[2] eq 30,  'Set 1c');

ok(($set2->set(10,20,30))[0] eq 10,  'Set 2a');
ok(($set2->set(10,20,30))[1] eq 42,  'Set 2b');
ok(($set2->set(10,20,30))[2] eq 30,  'Set 2c');

ok(ref (($set3->set(10,20,30))[0]) eq 'ARRAY',
				     'Set 3a1');
ok(($set3->set(10,20,30))[0]->[0] eq 41,  'Set 3a2');
ok(($set3->set(10,20,30))[0]->[1] eq 42,  'Set 3a3');
ok(($set3->set(10,20,30))[1] eq 20,  'Set 3b');
ok(($set3->set(10,20,30))[2] eq 30,  'Set 3c');

__END__
