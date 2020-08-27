#!/usr/bin/perl
#
# divide the subtitle corpus into train, dev and test set


use vars qw($opt_t $opt_d $opt_e $opt_D $opt_E);
use Getopt::Std;

getopts('t:d:e:D:E:');

my $TrainFile = $opt_t || 'train.ces';
my $DevFile   = $opt_d || 'dev.ces';
my $TestFile  = $opt_e || 'test.ces';

my $DevSize   = $opt_D || 2000;
my $TestSize  = $opt_E || 2000;


my %movies=();

# get devset

open O,">$DevFile" || die "cannot open devfile $DevFile\n";

my $count=0;
my $skip=0;

while (<>){
    if (/fromDoc=\"([^\"]+)\"/){
	my ($lang,$year,$movie) = split(/\//,$1);
	$skip = exists $movies{$movie}? 1 : 0;
	$movies{$movie}=1;
    }
    if (! $skip){ 
	print O $_; 
	if (/xtargets/){
	    $count++;
	}
    }
    if (/\<\/linkGrp\>/){
	last if ($count>$DevSize);
    }

}
print O "</cesAlign>\n";
close O;


## select test set



open O,">$TestFile" || die "cannot open testfile $TestFile\n";
print O '<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE cesAlign PUBLIC "-//CES//DTD XML cesAlign//EN" "">
<cesAlign version="1.0">';


my $count=0;
my $skip=0;

while (<>){
    if (/fromDoc=\"([^\"]+)\"/){
	my ($lang,$year,$movie) = split(/\//,$1);
	$skip = exists $movies{$movie}? 1 : 0;
	$movies{$movie}=1;
    }
    if (! $skip){ 
	print O $_; 
	if (/xtargets/){
	    $count++;
	}
    }
    if (/\<\/linkGrp\>/){
	last if ($count>$TestSize);
    }
}
print O "</cesAlign>\n";
close O;


## print remaining links as training set

open O,">$TrainFile" || die "cannot open trainfile $TrainFile\n";
print O '<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE cesAlign PUBLIC "-//CES//DTD XML cesAlign//EN" "">
<cesAlign version="1.0">';

my $skip=0;

while (<>){
    if (/fromDoc=\"([^\"]+)\"/){
	my ($lang,$year,$movie) = split(/\//,$1);
	$skip = exists $movies{$movie}? 1 : 0;
    }
    if (! $skip){ print O $_; }
}
close O;

foreach (keys %movies){
    print "$_\n";
}

