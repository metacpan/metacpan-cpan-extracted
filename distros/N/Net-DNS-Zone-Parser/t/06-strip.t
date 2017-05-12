#!/usr/bin/perl  -sw                  -*-perl-*-
# $Id: 06-strip.t 456 2005-07-06 18:30:44Z olaf $



use Test::More;
use strict;
use Net::DNS::Zone::Parser;




my $runs=1;
$runs=2 if $Net::DNS::Zone::Parser::NAMED_CHECKZONE;
plan tests=>$runs*9;
my $run=0;
while ($run<$runs){
    $Net::DNS::Zone::Parser::NAMED_CHECKZONE=0 if $run==1;

    if ($Net::DNS::Zone::Parser::NAMED_CHECKZONE){
	diag("Using the named-checkzone program as front-end\n")
	}else{
	diag("Perl implementation\n")
	}


    $run++;   
    
    
    my $parser;
    my $fh = new IO::File "> t/TMP_ZONE";
    if (defined $fh){
# Create a new object
	$parser = Net::DNS::Zone::Parser->new($fh);
    }else{
	$parser = Net::DNS::Zone::Parser->new();
    }
    
    
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     CREATE_RR => 1});
    
    
    my $array=$parser->get_array();
    is (  scalar @{$array}, 53 , "all RRs read from zonefile");
    
    my $soa;
    foreach my $rr (@{$array}){
	($rr->type eq "SOA") && ($soa=$rr )&& last;
    }
    
    is($soa->serial, 2003060988,"SOA serial as expected");
    
    
########################################################
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     STRIP_RRSIG => 1,
				     CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 28 , "all RRSIGs stripped");
    
    
########################################################
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     STRIP_NSEC => 1,
				     CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 35 , "all NSECs stripped");
    
    
########################################################
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     STRIP_DNSKEY => 1,
				     CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 48 , "all DNSKEYs stripped");
########################################################
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     STRIP_SEC => 1,
				     CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 16 , "all security RRs stripped");
    
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
########################################################
    $parser->read("t/test.db.disi",{ ORIGIN=> "disi.nl",
				     BUMP_SOA => 1,
				     CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    
    undef $soa;
    foreach my $rr (@{$array}){
	($rr->type eq "SOA") && ($soa=$rr )&& last;
    }
    
    is($soa->serial, 2003060989,"SOA serial as expected");

    
########################################################
    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.3",{ ORIGIN=> "foo.example",
				  BUMP_SOA => 1,
				  STRIP_DNSKEY=>1,
				  CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 426 , "Some other zone stripped from keys");
########################################################


    undef ($parser);
    $parser = Net::DNS::Zone::Parser->new();
    
    $parser->read("t/test.db.3",{ ORIGIN=> "foo.example",
				  BUMP_SOA => 1,
				  CREATE_RR => 1});
    
    
    $array=$parser->get_array();
    is (  scalar @{$array}, 430 , "Some other zone just parsed");
########################################################




} #END runs
