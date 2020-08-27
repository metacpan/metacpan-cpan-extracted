#!/usr/bin/env perl
#
# a simple script to merge sentence ID file produced by xces2moses
# with line_number file produced by the clean-corpus from Moses
#
# usage: retained-sentences.pl id-file < line-number-file > output
#

my $idfile = shift(@ARGV);
my @ids = ();
open F,"<$idfile" || die "cannot open idfile '$idfile'\n";

my $docs = undef;
my @ids = ();

while (<F>){
    if (s/^\#\#\s*//){
	chomp;
	$docs = $_;
    }
    else{
	push(@ids,join("\t",($docs,$_)));
    }
}
close F;

while (<>){
    chomp;
    print $ids[$_-1];
}

