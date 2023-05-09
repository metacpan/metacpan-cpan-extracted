#!/usr/bin/perl
# $Id: 06-update.t 1910 2023-03-30 19:16:30Z willem $  -*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 84;

use Net::DNS;


sub is_empty {
	local $_ = shift;

	return 0 unless defined $_;
	return 1 unless length $_;

	return 1 if /\\# 0/;
	return 1 if /; no data/;
	return 1 if /; rdlength = 0/;
	return 0;
}


#------------------------------------------------------------------------------
# Canned data.
#------------------------------------------------------------------------------

my $zone   = "example.com";
my $name   = "foo.example.com";
my $class  = "HS";
my $class2 = "CH";
my $type   = "A";
my $ttl	   = 43200;
my $rdata  = "10.1.2.3";

my $default = Net::DNS::Resolver->domain('example.org');	# resolver default domain

#------------------------------------------------------------------------------
# Packet creation.
#------------------------------------------------------------------------------

for my $packet ( Net::DNS::Update->new( $zone, $class ) ) {	# specified domain
	ok( $packet, 'new() returned packet' );
	is( $packet->header->opcode, 'UPDATE', 'header opcode correct' );
	my ($z) = $packet->zone;
	is( $z->zname,	$zone, 'zname from explicit argument' );
	is( $z->zclass,	$class,'zclass correct' );
	is( $z->ztype,	'SOA', 'ztype correct' );
}


for my $packet ( Net::DNS::Update->new() ) {
	my ($z) = $packet->zone;
	is( $z->zname, $default, 'zname from resolver defaults' );
}


#------------------------------------------------------------------------------
# RRset exists (value-independent).
#------------------------------------------------------------------------------

for my $rr ( yxrrset( my $arg = "$name $ttl $class $type" ) ) {
	ok( $rr, "yxrrset($arg)" );

	is( $rr->name,	$name, 'yxrrset - right name' );
	is( $rr->ttl,	0,     'yxrrset - ttl	0' );
	is( $rr->class, 'ANY', 'yxrrset - class ANY' );
	is( $rr->type,	$type, "yxrrset - type	$type" );
	ok( is_empty( $rr->rdstring ), 'yxrrset - data empty' );
}


#------------------------------------------------------------------------------
# RRset exists (value-dependent).
#------------------------------------------------------------------------------

for my $rr ( yxrrset( my $arg = "$name $ttl $class $type $rdata" ) ) {
	ok( $rr, "yxrrset($arg)" );

	is( $rr->name,	   $name,  'yxrrset - right name' );
	is( $rr->ttl,	   0,	   'yxrrset - ttl   0' );
	is( $rr->class,	   $class, "yxrrset - class $class" );
	is( $rr->type,	   $type,  "yxrrset - type  $type" );
	is( $rr->rdstring, $rdata, 'yxrrset - right data' );
}


#------------------------------------------------------------------------------
# RRset does not exist.
#------------------------------------------------------------------------------

for my $rr ( nxrrset( my $arg = "$name $ttl $class $type $rdata" ) ) {
	ok( $rr, "nxrrset($arg)" );

	is( $rr->name,	$name,	'nxrrset - right name' );
	is( $rr->ttl,	0,	'nxrrset - ttl	 0' );
	is( $rr->class, 'NONE', 'nxrrset - class NONE' );
	is( $rr->type,	$type,	"nxrrset - type	 $type" );
	ok( is_empty( $rr->rdstring ), 'nxrrset - data empty' );
}


#------------------------------------------------------------------------------
# Name is in use.
#------------------------------------------------------------------------------

for my $rr ( yxdomain( my $arg = "$name" ) ) {
	ok( $rr, "yxdomain($arg)" );

	is( $rr->name,	$name, 'yxdomain - right name' );
	is( $rr->ttl,	0,     'yxdomain - ttl	 0' );
	is( $rr->class, 'ANY', 'yxdomain - class ANY' );
	is( $rr->type,	'ANY', 'yxdomain - type	 ANY' );
	ok( is_empty( $rr->rdstring ), 'yxdomain - data empty' );
}

for my $rr ( yxdomain( my @arg = ( name => $name ) ) ) {
	ok( $rr, "yxdomain(@arg)" );

	is( $rr->name,	$name, 'yxdomain - right name' );
	is( $rr->ttl,	0,     'yxdomain - ttl	 0' );
	is( $rr->class, 'ANY', 'yxdomain - class ANY' );
	is( $rr->type,	'ANY', 'yxdomain - type	 ANY' );
	ok( is_empty( $rr->rdstring ), 'yxdomain - data empty' );
}


#------------------------------------------------------------------------------
# Name is not in use.
#------------------------------------------------------------------------------

for my $rr ( nxdomain( my $arg = "$name" ) ) {
	ok( $rr, "nxdomain($arg)" );

	is( $rr->name,	$name,	'nxdomain - right name' );
	is( $rr->ttl,	0,	'nxdomain - ttl	  0' );
	is( $rr->class, 'NONE', 'nxdomain - class NONE' );
	is( $rr->type,	'ANY',	'nxdomain - type  ANY' );
	ok( is_empty( $rr->rdstring ), 'nxdomain - data empty' );
}

for my $rr ( nxdomain( my @arg = ( name => $name ) ) ) {
	ok( $rr, "nxdomain(@arg)" );

	is( $rr->name,	$name,	'nxdomain - right name' );
	is( $rr->ttl,	0,	'nxdomain - ttl	  0' );
	is( $rr->class, 'NONE', 'nxdomain - class NONE' );
	is( $rr->type,	'ANY',	'nxdomain - type  ANY' );
	ok( is_empty( $rr->rdstring ), 'nxdomain - data empty' );
}


#------------------------------------------------------------------------------
# Add to an RRset.
#------------------------------------------------------------------------------

for my $rr ( rr_add( my $arg = "$name $ttl $class $type $rdata" ) ) {
	ok( $rr, "rr_add($arg)" );

	is( $rr->name,	   $name,  'rr_add - right name' );
	is( $rr->ttl,	   $ttl,   "rr_add - ttl   $ttl" );
	is( $rr->class,	   $class, "rr_add - class $class" );
	is( $rr->type,	   $type,  "rr_add - type  $type" );
	is( $rr->rdstring, $rdata, 'rr_add - right data' );
}

for my $rr ( rr_add( my $arg = "$name $class $type $rdata" ) ) {
	my $rr	= rr_add($arg);

	ok( $rr, "rr_add($arg)" );
	is( $rr->name,	   $name,  'rr_add - right name' );
	is( $rr->ttl,	   86400,  "rr_add - ttl   86400" );
	is( $rr->class,	   $class, "rr_add - class $class" );
	is( $rr->type,	   $type,  "rr_add - type  $type" );
	is( $rr->rdstring, $rdata, 'rr_add - right data' );
}


#------------------------------------------------------------------------------
# Delete an RRset.
#------------------------------------------------------------------------------

for my $rr ( rr_del( my $arg = "$name $class $type" ) ) {
	ok( $rr, "rr_del($arg)" );

	is( $rr->name,	$name, 'rr_del - right name' );
	is( $rr->ttl,	0,     'rr_del - ttl   0' );
	is( $rr->class, 'ANY', 'rr_del - class ANY' );
	is( $rr->type,	$type, "rr_del - type  $type" );
	ok( is_empty( $rr->rdstring ), 'rr_del - data empty' );
}

#------------------------------------------------------------------------------
# Delete All RRsets From A Name.
#------------------------------------------------------------------------------

for my $rr ( rr_del( my $arg = "$name" ) ) {
	ok( $rr, "rr_del($arg)" );

	is( $rr->name,	$name, 'rr_del - right name' );
	is( $rr->ttl,	0,     'rr_del - ttl   0' );
	is( $rr->class, 'ANY', 'rr_del - class ANY' );
	is( $rr->type,	'ANY', 'rr_del - type  ANY' );
	ok( is_empty( $rr->rdstring ), 'rr_del - data empty' );
}


#------------------------------------------------------------------------------
# Delete An RR From An RRset.
#------------------------------------------------------------------------------

for my $rr ( rr_del( my $arg = "$name $class $type $rdata" ) ) {
	ok( $rr, "rr_del($arg)" );

	is( $rr->name,	   $name,  'rr_del - right name' );
	is( $rr->ttl,	   0,	   'rr_del - ttl   0' );
	is( $rr->class,	   'NONE', 'rr_del - class NONE' );
	is( $rr->type,	   $type,  "rr_del - type  $type" );
	is( $rr->rdstring, $rdata, 'rr_del - right data' );
}


#------------------------------------------------------------------------------
# Make sure RRs in an update packet have the same class as the zone, unless
# the class is NONE or ANY.
#------------------------------------------------------------------------------

for my $packet ( Net::DNS::Update->new( $zone, $class ) ) {
	ok( $packet, 'packet created' );

	$packet->push( "pre", yxrrset("$name $class $type $rdata") );
	$packet->push( "pre", yxrrset("$name $class2 $type $rdata") );
	$packet->push( "pre", yxrrset("$name $class2 $type") );
	$packet->push( "pre", nxrrset("$name $class2 $type") );

	my @pre = $packet->pre;

	is( scalar(@pre),   4,	    '"pre" length correct' );
	is( $pre[0]->class, $class, 'first class right' );
	is( $pre[1]->class, $class, 'second class right' );
	is( $pre[2]->class, 'ANY',  'third class right' );
	is( $pre[3]->class, 'NONE', 'fourth class right' );
}

