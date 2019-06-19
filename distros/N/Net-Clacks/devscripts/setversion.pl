#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.010_001;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp;
our $VERSION = 6.0;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

# PAGECAMEL  (C) 2008-2019 Rene Schickbauer
# Developed under Artistic license

my $newversion = shift @ARGV || "???";

if($newversion eq "???") {
    print "Usage: perl devscripts/setversion.pl 9.87\n";
    exit(0);
}

print "Searching files...\n";
my @files = (find_pm('lib'), find_pm('devscripts'), find_pm('example'));

print "Changing files:\n";
foreach my $file (@files) {
    print "Editing $file...\n";

    my @lines;
    open(my $ifh, "<", $file) or die($ERRNO);
    @lines = <$ifh>;
    close $ifh;

    open(my $ofh, ">", $file) or die($ERRNO);
    foreach my $line (@lines) {
        $line =~ s/VERSION = \d\.\d+/VERSION = $newversion/g;
        print $ofh $line;
    }
    close $ofh;
}
print "Done.\n";
exit(0);



sub find_pm {
    my ($workDir) = @_;

    my @files;
    opendir(my $dfh, $workDir) or die($ERRNO);
    while((my $fname = readdir($dfh))) {
        next if($fname eq "." || $fname eq ".." || $fname eq ".hg");
        $fname = $workDir . "/" . $fname;
        if(-d $fname) {
            push @files, find_pm($fname);
        } elsif($fname =~ /\.p[lm]$/i && -f $fname) {
            push @files, $fname;
        }
    }
    closedir($dfh);
    return @files;
}
