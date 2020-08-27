#!/usr/bin/perl
#

use strict;

my $corpus = shift(@ARGV) || '*';

my %SKIP = (
    'DOGCv0.1' => 1,
    'Europarl3' => 1,
    'example' => 1,
    'mytest' => 1,
    'News-Commentary' => 1,
    'News-Commentaryv9.0' => 1,
    'OpenSubtitles2011' => 1,
    'OpenSubtitles2012' => 1,
    'OpenSubtitles2013' => 1,
    'OpenSubtitles2015' => 1,
    'SETIMES' => 1,
    );

## minimum number of tokens / sentences
my $MINTOK = 0;
my $MINSENT = 100;


my $OPUSHOME = '/proj/nlpl/data/OPUS';
my $OPUSHTML = $OPUSHOME.'/html';
my $OPUSCORPORA = $OPUSHOME.'/corpus';

my @infofiles = glob("$OPUSCORPORA/$corpus/xml/*.info");

my %countD=();
my %countF=();
my %countS=();
my %countT=();
my %countB=();

my %totalD=();
my %totalF=();
my %totalS=();
my %totalT=();
my %totalB=();


my %langF=();
my %langS=();
my %langT=();

my %lang=();
my %bitexts=();
my %bitexts2=();

my $langTotalF = 0;
my $langTotalS = 0;
my $langTotalT = 0;

foreach my $f (@infofiles){

    $f=~/\/([^\/]+)\/xml\//;
    next if (exists $SKIP{$1});

    open F,"<$f" || die "cannot read from $f";
    my @lines = <F>;
    close F;
    next if ($lines[-1]<$MINTOK);

    if ($f=~/^.*\/([^\/]+)-([^\/]+?)(\.tmx|txt)?\.info$/){
	next if ($lines[-3]<$MINSENT);
	my $type = 'xml';
	my $s=$1;
	my $t=$2;
	if ($f=~/^.*\/([^\/]+?)-([^\/]+?)\.(tmx|txt).info$/){
	    $s=$1;
	    $t=$2;
	    $type = $3;
	}
	else{
	    $countD{$type}{"$s-$t"}+=$lines[0];
	    $totalD{$type}+=$lines[0];
	    $bitexts{"$s-$t"}++;
	    my ($s2,$t2)=($s,$t);
	    $s2=~s/\_.*$//;
	    $t2=~s/\_.*$//;
	    $bitexts2{"$s2-$t2"}++;
	}
	$countF{$type}{"$s-$t"}+=$lines[-3];
	$countS{$type}{"$s-$t"}+=$lines[-2];
	$countT{$type}{"$s-$t"}+=$lines[-1];
	$countB{$type}{"$s-$t"}+=$lines[-2]+$lines[-1];
	$totalF{$type}+=$lines[-3];
	$totalS{$type}+=$lines[-2];
	$totalT{$type}+=$lines[-1];
	$totalB{$type}+=$lines[-2]+$lines[-1];
    }
    elsif ($f=~/^.*\/([^\/]*).info$/){
	next if ($lines[1]<$MINSENT);
	my $l = $1;
	$langF{$l}+=$lines[0];
	$langS{$l}+=$lines[1];
	$langT{$l}+=$lines[2];
	$langTotalF+=$lines[0];
	$langTotalS+=$lines[1];
	$langTotalT+=$lines[2];
	$l=~s/\_.*$//;
	$lang{$l}++;
    }
}

print "Number of languages (including variants):      ", scalar keys %langT,"\n";
print "Number of languages (without variants):        ", scalar keys %lang,"\n\n";
print "Number of language pairs (including variants): ", scalar keys %bitexts,"\n";
print "Number of language pairs (without variants):   ", scalar keys %bitexts2,"\n\n";

#################################################################

print "Monolingual data\n\n";
print "lang & files & sents & tokens \\\\\n\\hline\n";

foreach my $l (sort {$langT{$b} <=> $langT{$a}} keys %langT){
    printf "%10s \& %10s \& %10s \& %10s \\\\\n",
    $l,
    pretty_number($langF{$l}),
    pretty_number($langS{$l}),
    pretty_number($langT{$l});
}
print "\\hline\n";

printf "%10s \& %10s \& %10s \& %10s \\\\\n",
    'total',
    pretty_number($langTotalF),
    pretty_number($langTotalS),
    pretty_number($langTotalT);

#################################################################

foreach my $type (keys %countB){

    print "\nBilingual data ($type)\n\n";

    if ($type eq 'xml'){
	print "lang & docs & sents & source & target \\\\\n\\hline\n";
	my $nr = 1;
	foreach my $l (sort {$countB{$type}{$b} <=> $countB{$type}{$a}} keys %{$countB{$type}}){
	    printf "%10s \& %10s \& %10s \& %10s \& %10s \\\\ \# (%d) \n",
	    $l,
	    pretty_number($countD{$type}{$l}),
	    pretty_number($countF{$type}{$l}),
	    pretty_number($countS{$type}{$l}),
	    pretty_number($countT{$type}{$l}),
	    $nr;
	    $nr++;
	}
	print "\\hline\n";
	printf "%10s \& %10s \& %10s \& %10s \& %10s \\\\\n",
	'total',
	pretty_number($totalD{$type}),
	pretty_number($totalF{$type}),
	pretty_number($totalS{$type}),
	pretty_number($totalT{$type});
    }
    else{
	print "lang & sents & source & target \\\\\n\\hline\n";
	foreach my $l (sort {$countB{$type}{$b} <=> $countB{$type}{$a}} keys %{$countB{$type}}){
	    printf "%10s \& %10s \& %10s \& %10s \\\\\n",
	    $l,
	    pretty_number($countF{$type}{$l}),
	    pretty_number($countS{$type}{$l}),
	    pretty_number($countT{$type}{$l});
	}
	print "\\hline\n";
	printf "%10s \& %10s \& %10s \& %10s \\\\\n",
	'total',
	pretty_number($totalF{$type}),
	pretty_number($totalS{$type}),
	pretty_number($totalT{$type});
    }
}

#################################################################


sub pretty_number{
    my $nr = shift;
    my $dec = shift || 1;
    if ($nr>1000000000){
      return sprintf("%.${dec}fG",$nr/1000000000);
    }
    if ($nr>100000){
      return sprintf("%.${dec}fM",$nr/1000000);
    }
    if ($nr>100){
      return sprintf("%.${dec}fk",$nr/1000);
    }
    return $nr;
}


