#!/usr/bin/perl  -sw 
# Test script for Zone functionalty
# $Id: 04-generate.t 454 2005-07-06 13:38:31Z olaf $
# 
# Called in a fashion simmilar to:
# /usr/bin/perl -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.1/i386-freebsd \
# -I/usr/lib/perl5/5.6.1 -e 'use Test::Harness qw(&runtests $verbose); \
# $verbose=0; runtests @ARGV;' t/01-zonetest.t

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More;
use strict;
use Net::DNS::SEC;

#use Data::Dumper;









use Shell qw (which);
my $named_checkzone = which("named-checkzone");
$named_checkzone =~ s/\s+$//;
my $nocheckzone=0;

if ( !( -x $named_checkzone )){
    diag "Some additional tests are performed if named-checkzone is in your path.";

$nocheckzone=1;
}





use Net::DNS::Zone::Parser qw ( processGENERATEarg );


my $runs=1;
$runs=2 if $Net::DNS::Zone::Parser::NAMED_CHECKZONE;
plan tests=>$runs*8;
my $run=0;
while ($run<$runs){

    $Net::DNS::Zone::Parser::NAMED_CHECKZONE=0 if $run==1;
    if ($Net::DNS::Zone::Parser::NAMED_CHECKZONE){
	diag("Using the named-checkzone program as front-end\n")
	}else{
	diag("Perl implementation\n")
	}

    
    $run++;   
    
    
# Create a new object
    my $parser = Net::DNS::Zone::Parser->new();
    ok( defined($parser), "Parser object creation");                      
    
    use_ok('Net::DNS');                                                
    
    $parser->read("t/test.db.generate",{ ORIGIN=> "foo.test",
					 CREATE_RR => 1});
    
    is( processGENERATEarg('$.bla.${1,5,x}.\$.foo',10,"example.com."),'10.bla.0000b.$.foo.example.com.',"processGENERATEarg does something correct");
    
    is( processGENERATEarg('\$$\${1,5,x}${10,5,o}-${10,0,x}.\$.foo',0,"example.com."),'$0${1,5,x}00012-a.$.foo.example.com.',"processGENERATEarg even solves ugly ones");
    
    
    my $fh = new IO::File "> t/TMP_ZONE";
    
  SKIP: {
      skip "Could not open t/TMP_ZONE for writing, Check your file permissions, these tests are important!", 1, unless defined $fh;
      
      my $parser2 = Net::DNS::Zone::Parser->new($fh);
      $parser2->read("t/test.db.7",{ ORIGIN=> "foo.test",
				     CREATE_RR => 1});
      


      my $RRarray=$parser2->get_array;


      is ( @{$RRarray}, 37, "Generate retuns proper number of  RRs.");
      
      
      foreach my $rr (@{$RRarray}){
	  is("10.0.1.1",$rr->rdatastr,"Correctly generated RDATA for A") if
	      ($rr->name eq "1.foo.test" && $rr->type eq "A");
	  
	  is("10.0.1.1.in-addr.arpa.",$rr->rdatastr,"Correctly generated RDATA for PTR") if
	      ($rr->name eq "1.foo.test" && $rr->type eq "PTR");
	  
	  
	  
      }
  }
    
    
    
    
    
  SKIP:
    {
	
	skip 
	    "No named-checkzone found on the system", 1  if ($nocheckzone || ! defined ($fh));
	
	system("$named_checkzone foo.test t/TMP_ZONE > /dev/null 2>&1");
	is ($?,0,"named_checkzone failed checking the zone");
    };  #  end SKIP
    $fh->close;    
}




