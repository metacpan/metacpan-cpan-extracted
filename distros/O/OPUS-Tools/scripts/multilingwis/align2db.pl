#!/bin/env perl
#-*-perl-*-

use strict;

use utf8;
use open qw(:utf8 :std);

use DB_File;
use vars qw($opt_x $opt_s $opt_t $opt_d);
use Getopt::Std;
use DBM_Filter;

getopts('d:s:t:x');

my $SentAlignFile = shift(@ARGV);
my $WordAlignFile = shift(@ARGV);

my $srclang = $opt_s;
my $trglang = $opt_t;

open S,"gzip -cd <$SentAlignFile |" || die "cannot read from $SentAlignFile";
open W,"gzip -cd <$WordAlignFile |" || die "cannot read from $WordAlignFile";

my %alg = ();
my $first = 1;

my ($sdoc,$tdoc,$sids,$tids);
my $count = 0;

while (<S>){
    chomp;

    ## not XML format is still standard:
    ## old style ID file with docIDs and sentIDs on TAB separated lines
    unless ($opt_x){
	if (/\<\?xml/){
	    $opt_x = 1;
	    next;
	}
	($sdoc,$tdoc,$sids,$tids) = split(/\t/);
    }
    ## new style: XML sentence alignment file
    else{
	if (/fromDoc=\"(.*?)\"/){
	    $sdoc = $1;
	}
	if (/toDoc=\"(.*?)\"/){
	    $tdoc = $1;
	}
	if (/xtargets=\"(.*?)\"/){
	    ($sids,$tids) = split(/\;/,$1);
	}
	else{
	    next;
	}
    }

    $count++;
    print STDERR '.' unless ($count % 2000);
    print STDERR " $count\n" unless ($count % 100000);

    # set source and target language if not set
    # (use first element in file path)
    unless ($srclang){
	$srclang = $sdoc;
	$srclang =~s/^([^\/]+)\/.*$/$1/;
    }
    unless ($trglang){
	$trglang = $tdoc;
	$trglang =~s/^([^\/]+)\/.*$/$1/;
    }

    ## open DB after the first entry
    ## (need to check srclang and trglang first)
    if ($first){
	my $DBFile = $opt_d || "$srclang-$trglang.db";
	my $db = tie %alg, 'DB_File', $DBFile;
	$db->Filter_Push('utf8');
	$first = 0;
    }

    my @src = split(/\s+/,$sids);
    my @trg = split(/\s+/,$tids);

    my $walign = <W>;
    chomp $walign;

    foreach my $s (@src){
	my $a = join("\t",$tdoc,$sids,$tids,$walign);
	$alg{"$sdoc:$s"} = $a;
    }
    # reverse alignment
    foreach my $t (@trg){
	my @alg = split(/\s+/,$walign);
	my @reverse = ();
	foreach (@alg){
	    my ($x,$y) = split(/\-/);
	    push (@reverse,"$y-$x");
	}
	$walign = join(' ',@reverse);
	my $a = join("\t",$sdoc,$tids,$sids,$walign);
	$alg{"$tdoc:$t"} = $a;
    }
}

$alg{"__srclang__"} = $srclang;
$alg{"__trglang__"} = $trglang;
