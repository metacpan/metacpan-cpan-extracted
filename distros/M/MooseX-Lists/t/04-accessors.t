#! /usr/bin/perl
# $Id: 04-accessors.t,v 1.2 2010/01/14 10:05:05 dk Exp $

use strict;
use warnings;

use Moose;
use MooseX::Lists;
use Test::More tests => 11;

has_list a => (
	isa => 'ArrayRef', 
	is => 'rw', 
	reader => 'ra', 
	writer => 'sa',
	clearer => 'ca'
	);
has_list h => (
	isa => 'HashRef', 
	is => 'rw', 
	reader => 'rh', 
	writer => 'sh',
	clearer => 'ch'
	);

has_list a2 => (
	isa => 'ArrayRef', 
	is => 'rw', 
	accessor => 'aq', 
	);
has_list h2 => (
	isa => 'HashRef', 
	is => 'rw', 
	accessor => 'hq',
	);

my $x = main-> new( a => [1,2,3], h => { 1, 2, 3, 4});
ok( 123 eq join('', $x->ra), "array/custom reader");
$x-> sa(1,2,3);
ok( 123 eq join('', $x->ra), "array/custom writer/list");
$x-> sa([1,2,3]);
ok((($x->ra)[0] =~ /ARRAY/), "array/custom writer/ref");
$x-> sa;
ok( '' eq join('', $x->ra), "array/custom writer/empty");
$x-> sa(1,2,3);
$x-> ca;
ok( '' eq join('', $x->ra), "array/custom clearer");

ok( 1234 eq join('', sort $x->rh), "hash/custom reader");
$x-> sh(1,2,3,4);
ok( 1234 eq join('', sort $x->rh), "hash/custom writer");
$x-> sh;
ok( '' eq join('', $x->rh), "hash/custom writer/empty");
$x-> sh(1,2,3,4);
$x-> ch;
ok( '' eq join('', sort $x->rh), "hash/custom clearer");

$x-> aq(1,2,3,4);
ok( 1234 eq join('', $x->aq), "array/custom accessor");
$x-> hq(1,2,3,4);
ok( 1234 eq join('', sort $x->hq), "hash/custom accessor");
