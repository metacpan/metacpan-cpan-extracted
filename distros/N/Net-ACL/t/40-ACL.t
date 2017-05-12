#!/usr/bin/perl -wT

# $Id: 40-ACL.t,v 1.2 2003/05/27 23:41:57 unimlo Exp $

use strict;

use Test::More tests => 34;

# Use
use_ok('Net::ACL');
use_ok('Net::ACL::Rule');
use_ok('Net::ACL::Match::IP');
use_ok('Net::ACL::Set::Scalar');
use Net::ACL::Rule qw( :action );

# Construction
my $erule = new Net::ACL::Rule();
ok(ref $erule eq 'Net::ACL::Rule','Simple Rule construction');

my $elist = new Net::ACL();
ok(ref $elist eq 'Net::ACL','Simple ACL construction');

my $rule1 = new Net::ACL::Rule(
	Action	=> ACL_DENY,
	Match	=> {
		IP	=> [0,'10.10.0.0/16']
		}
	);
ok(ref $rule1 eq 'Net::ACL::Rule','Rule construction 1');

my $rule2 = new Net::ACL::Rule(
	Action	=> ACL_PERMIT,
	Match	=> {
		IP	=> [0,'10.0.0.0/8']
		}
	);
ok(ref $rule2 eq 'Net::ACL::Rule','Rule construction 2');

my $rule3 = new Net::ACL::Rule(
	Action	=> ACL_PERMIT,
	Match	=> {
		IP	=> [0,'127.0.0.1']
		}
	);
ok(ref $rule3 eq 'Net::ACL::Rule','Rule construction 3');

my $rule1b = new Net::ACL::Rule(
	Action	=> ACL_CONTINUE,
	Match	=> {
		IP	=> [0,'127.0.0.0/8']
		},
	Set	=> {
		Scalar	=> [0,'127.0.0.1']
		}
	);
ok(ref $rule1b eq 'Net::ACL::Rule','Rule construction 4');

my $filter = new Net::ACL(
	Name	=> 42,
	Type	=> 'ip-access-list',
	Rule	=> {
		10	=> $rule1,
		20	=> $rule2,
		30	=> $rule3
		}
	);

ok(ref $filter eq 'Net::ACL','ACL construction 1');

my $modifyer = new Net::ACL(
	Name	=> 42,
	Type	=> 'ip-modifyer',
	Rule	=> {
		10	=> $rule1,
		15	=> $rule1b,
		20	=> $rule2,
		30	=> $rule3
		}
	);

ok(ref $modifyer eq 'Net::ACL','ACL construction 2');

# Clone
my $clone1 = $filter->clone;
ok(ref $clone1 eq 'Net::ACL','Cloning');
my $clone2 = clone Net::ACL($clone1);
ok(ref $clone2 eq 'Net::ACL','Clone construction');
my $clone3 = renew Net::ACL(
	Name =>	42,
	Type => 'ip-access-list'
	);
ok(ref $clone3 eq 'Net::ACL','Renew reconstruction 1');
my $clone4 = renew Net::ACL("$clone1");
ok(ref $clone4 eq 'Net::ACL','Renew reconstruction 2');

# Name and Type
ok(! defined $clone1->name,'Name of clone');
ok($clone3->type eq 'ip-access-list','Type of clone');
$clone3->name('foobar');
ok($clone3->name eq 'foobar',        'Name modification');
$clone3->type('baz');
ok($clone3->type eq 'baz',           'Type modification 1');
$clone3->type(undef);
ok(! defined $clone3->type,          'Type modification 2');

# Clone cont.
my $clone = renew Net::ACL(
	Name =>	'foobar'
	);
ok(ref $clone eq 'Net::ACL','Renew reconstruction 3');

# Match
ok($elist->match('10.0.0.0')    eq ACL_PERMIT,'ACL match 1 (implicit permit)');
ok($clone->match('10.10.10.10') eq ACL_DENY,  'ACL match 2 (explicit deny)');
ok($clone->match('10.20.30.40') eq ACL_PERMIT,'ACL match 3 (explicit permit)');
ok($clone->match('1.2.3.4')     eq ACL_DENY,  'ACL match 4 (implicit deny)');
ok($clone->match('127.0.0.1')   eq ACL_PERMIT,'ACL match 5 (implicit host permit)');

# Query
ok(($modifyer->query('10.20.30.40'))[0] eq ACL_PERMIT,    'ACL query 1 (permit)');
ok(($modifyer->query('10.20.30.40'))[1] eq '10.20.30.40', 'ACL query 2 (unmodified)');
ok(($modifyer->query('127.0.0.1'  ))[0] eq ACL_PERMIT,    'ACL query 3 (permit)');
ok(($modifyer->query('127.0.0.10' ))[0] eq ACL_PERMIT,    'ACL query 4 (permit modified)');
ok(($modifyer->query('127.0.0.10' ))[1] eq '127.0.0.1',   'ACL query 5 (permit modified)');
ok(($modifyer->query('128.0.0.0'  ))[0] eq ACL_DENY,      'ACL query 6 (deny)');
ok(! defined(($modifyer->query('128.0.0.0'))[1]),         'ACL query 7 (deny undefined)');

__END__
