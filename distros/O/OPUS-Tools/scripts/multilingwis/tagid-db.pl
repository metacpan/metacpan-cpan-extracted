#!/bin/env perl
#-*-perl-*-

use strict;

use utf8;
use open qw(:utf8 :std);

use DB_File;
use vars qw($opt_d $opt_s);
use Getopt::Std;
use DBM_Filter;

getopts('d:s:');

my $docDB = $opt_d || 'docid.db';
my $sentDB = $opt_s || 'sentid.db';

my %docIDs = ();
my %sentIDs = ();

my $docDB = tie %docIDs, 'DB_File', $docDB;
my $sentDB = tie %sentIDs, 'DB_File', $sentDB;

## DBM_FILTER
$docDB->Filter_Push('utf8');
$sentDB->Filter_Push('utf8');


my $doc = undef;
my $sent = undef;

my $docid = 1;
my $sentid = 1;
my $wordid = 1;

my $tokenNr=0;
my $count = 0;

while (<>){
    $count++;
    print STDERR '.' unless ($count % 100000);
    print STDERR " $count ($docid/$sentid/$wordid)\n" unless ($count % 5000000);
    my ($d,$t) = split(/\:/);
    if ($d ne $doc){
	if ($sent){
	    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
	}
	if ($doc){
	    $docIDs{$doc} = $docid;
	    $docid++;
	}
	$doc = $d;
	$tokenNr = 0;
    }
    if ($t=~/<s\s+[^>]*id\=\"([^\"]+)\"/){
	if ($sent){
	    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
	}
	$sent = $1;
	$sentIDs{"$docid:$sent"} = "$sentid\t$wordid";
	$sentid++;
	$tokenNr = 0;
    }
    elsif ($t=~/<w\s+/){
	$tokenNr++;
	$wordid++;
    }
}

if ($doc and $docid){
    $docIDs{$doc} = $docid;
}
if ($sent and $docid){
    $sentIDs{"$docid:$sent"} .= "\t".$tokenNr;
}
