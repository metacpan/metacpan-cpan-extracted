# $Id: 06-update.t 1408 2015-10-06 20:35:56Z willem $  -*-perl-*-

use strict;
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

#------------------------------------------------------------------------------
# Packet creation.
#------------------------------------------------------------------------------

{
	my $packet = new Net::DNS::Update( $zone, $class );
	my ($z) = ( $packet->zone )[0];

	ok( $packet, 'new() returned packet' );
	is( $packet->header->opcode, 'UPDATE', 'header opcode correct' );
	is( $z->zname,		     $zone,    'zname correct' );
	is( $z->zclass,		     $class,   'zclass correct' );
	is( $z->ztype,		     'SOA',    'ztype correct' );
}


{
	local $ENV{'LOCALDOMAIN'};				# overides config files
	my $packet = eval { new Net::DNS::Update(undef); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "argument undefined\t[$exception]" );
}


#------------------------------------------------------------------------------
# RRset exists (value-independent).
#------------------------------------------------------------------------------

{
	my $arg = "$name $ttl $class $type";
	my $rr	= yxrrset($arg);

	ok( $rr, "yxrrset($arg)" );				#9
	is( $rr->name,	$name, 'yxrrset - right name' );
	is( $rr->ttl,	0,     'yxrrset - ttl	0' );
	is( $rr->class, 'ANY', 'yxrrset - class ANY' );
	is( $rr->type,	$type, "yxrrset - type	$type" );
	ok( is_empty( $rr->rdstring ), 'yxrrset - data empty' );
}

#------------------------------------------------------------------------------
# RRset exists (value-dependent).
#------------------------------------------------------------------------------

{
	my $arg = "$name $ttl $class $type $rdata";
	my $rr	= yxrrset($arg);

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

{
	my $arg = "$name $ttl $class $type $rdata";
	my $rr	= nxrrset($arg);

	ok( $rr, "nxrrset($arg)" );				#21
	is( $rr->name,	$name,	'nxrrset - right name' );
	is( $rr->ttl,	0,	'nxrrset - ttl	 0' );
	is( $rr->class, 'NONE', 'nxrrset - class NONE' );
	is( $rr->type,	$type,	"nxrrset - type	 $type" );
	ok( is_empty( $rr->rdstring ), 'nxrrset - data empty' );
}


#------------------------------------------------------------------------------
# Name is in use.
#------------------------------------------------------------------------------

{
	my @arg = "$name";
	my $rr	= yxdomain(@arg);

	ok( $rr, "yxdomain(@arg)" );				#27
	is( $rr->name,	$name, 'yxdomain - right name' );
	is( $rr->ttl,	0,     'yxdomain - ttl	 0' );
	is( $rr->class, 'ANY', 'yxdomain - class ANY' );
	is( $rr->type,	'ANY', 'yxdomain - type	 ANY' );
	ok( is_empty( $rr->rdstring ), 'yxdomain - data empty' );
}

{
	my @arg = ( name => $name );
	my $rr = yxdomain(@arg);

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

{
	my @arg = "$name";
	my $rr	= nxdomain(@arg);

	ok( $rr, "nxdomain(@arg)" );				#39
	is( $rr->name,	$name,	'nxdomain - right name' );
	is( $rr->ttl,	0,	'nxdomain - ttl	  0' );
	is( $rr->class, 'NONE', 'nxdomain - class NONE' );
	is( $rr->type,	'ANY',	'nxdomain - type  ANY' );
	ok( is_empty( $rr->rdstring ), 'nxdomain - data empty' );
}

{
	my @arg = ( name => $name );
	my $rr = nxdomain(@arg);

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

{
	my $arg = "$name $ttl $class $type $rdata";
	my $rr	= rr_add($arg);

	ok( $rr, "rr_add($arg)" );				#51
	is( $rr->name,	   $name,  'rr_add - right name' );
	is( $rr->ttl,	   $ttl,   "rr_add - ttl   $ttl" );
	is( $rr->class,	   $class, "rr_add - class $class" );
	is( $rr->type,	   $type,  "rr_add - type  $type" );
	is( $rr->rdstring, $rdata, 'rr_add - right data' );
}

{
	my $arg = "$name      $class $type $rdata";
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

{
	my $arg = "$name $class $type";
	my $rr	= rr_del($arg);

	ok( $rr, "rr_del($arg)" );				#63
	is( $rr->name,	$name, 'rr_del - right name' );
	is( $rr->ttl,	0,     'rr_del - ttl   0' );
	is( $rr->class, 'ANY', 'rr_del - class ANY' );
	is( $rr->type,	$type, "rr_del - type  $type" );
	ok( is_empty( $rr->rdstring ), 'rr_del - data empty' );
}

#------------------------------------------------------------------------------
# Delete All RRsets From A Name.
#------------------------------------------------------------------------------

{
	my $arg = "$name";
	my $rr	= rr_del($arg);

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

{
	my $arg = "$name $class $type $rdata";
	my $rr	= rr_del($arg);

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

{
	my $packet = Net::DNS::Update->new( $zone, $class );
	ok( $packet, 'packet created' );			#81

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

