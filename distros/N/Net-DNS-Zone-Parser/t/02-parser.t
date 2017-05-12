#!/usr/bin/perl  -sw 
# Test script for Zone functionalty
# $Id: 02-parser.t 726 2008-09-16 10:33:27Z olaf $
# 
# Called in a fashion simmilar to:
# /usr/bin/perl -Iblib/arch -Iblib/lib -I/usr/lib/perl5/5.6.1/i386-freebsd \
# -I/usr/lib/perl5/5.6.1 -e 'use Test::Harness qw(&runtests $verbose); \
# $verbose=0; runtests @ARGV;' t/01-zonetest.t

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More tests=>9;
use strict;






#use Data::Dumper;

BEGIN {use_ok('Net::DNS::Zone::Parser');
       use_ok('Net::DNS::SEC');
      }                                 # test 2


use Shell qw (which);
my $named_compilezone = which("named-compilezone");
$named_compilezone =~ s/\s+$//;




my $nocompilezone=0;


if ( !( -x $named_compilezone )){
    diag "Some additional tests are performed if named-compilezone is in your path.";
    $nocompilezone=1;
}

if (! $nocompilezone ){
    my $named_compilezone_version=`$named_compilezone -v`;
    my($branch,$major,$minor,$other)= $named_compilezone_version=~/(\d+)\.(\d+)\.(\d+)(.*)/;
    if ($branch<9 || ($branch==9 && $major<4) ){
	diag ("This version of named-compilezone does not know about DNSSEC, some tests will be skipped");
	$nocompilezone=1;
    }
}


my $parser;
my $fh = new IO::File "> t/TMP_ZONE";
if (defined $fh){
# Create a new object
    $parser = Net::DNS::Zone::Parser->new($fh);
}else{
    $parser = Net::DNS::Zone::Parser->new();
}
    

ok( defined($parser), "Parser object creation");                        # test 3


$parser->read("t/test.db",{ ORIGIN=> "foo.test",
				     CREATE_RR => 1});


my $array=$parser->get_array();
is (  scalar @{$array}, 12 , "12 RRs read from zonefile");


#
#  Some minor content checks on the zone content.
# 

my $sigrr=Net::DNS::RR->new('z.x.c.d.foo.test.       1500    IN      RRSIG   AAAA  1  3  172800  20011028163938 (
                     20010928163938 39250  bla.foo.test.
                     AeYY2IgScHDWq6zRfyzCdimqA3de9Sb/Ivw7PoMcvJr7f
                     7gtqF9IWpTdH7KNd1tPAHbiIAfjmsXIgOOAL0TChQ== )');

foreach my $rr (@{$array}){

    is ($rr->string, 'z.x.c.d.foo.test.	1500	IN	TXT	"Multiple line f.nny" "<xml> typed </xml" "text resource record"', "multiline TXT RR parsed correctly")
      if ($rr->name eq "z.x.c.d.foo.test" && $rr->type eq "TXT");

    
    is( $rr->string,'foo.test.	3600	IN	SOA	ns1.foo.test. root.localhost. (
					2002021201	; Serial
					450	; Refresh
					600	; Retry
					345600	; Expire
					300 )	; Minimum TTL'
      ,"SOA RR parsed correctly")
  if ($rr->name eq "foo.test" && $rr->type eq "SOA");

    is ($rr->string, $sigrr->string,
    "dname in RRSIG completed.") if ($rr->name eq "z.x.c.d.foo.test" && $rr->type eq "RRSIG");


}




if (! $nocompilezone ){

    open(VERSION,"$named_compilezone -v|");
    $_=<VERSION>;
    chop;
    /^(\d+)\.(\d+)\.(\d+)/;
    my ($release,$major,$minor)=($1,$2,$3);
    $nocompilezone=$_ unless ($release >= 9 && $major >= 3 && $minor>= 0); 	

}


SKIP: {
  skip "No suitable named-compilezone ($nocompilezone) found on the system", 
    1 if 
      $nocompilezone || ! defined ($fh);
    require File::Temp;
    my $tmpfh = File::Temp->new();
    my $tmpfname = $tmpfh->filename;

  system($named_compilezone ,"-q","-i","none","-o",$tmpfname,"foo.test","t/TMP_ZONE");
    is ($?,0,"named_compilezone checked the zone");
};  #  end SKIP







$parser->read("t/root",{ ORIGIN=> ".",
				     CREATE_RR => 1});


$array=$parser->get_array();
is (  scalar @{$array}, 2509 , "2509 RRs read from zonefile");

