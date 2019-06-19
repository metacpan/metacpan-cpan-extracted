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


print "Searching files...\n";
my @files = (find_pm('lib'), find_pm('devscripts'));
#my @files = find_pm('server');

print "Changing files:\n";
foreach my $file (@files) {
    my $inserted = 0;
    print "Editing $file...\n";

    my @lines;
    open(my $ifh, "<", $file) or die($ERRNO);
    @lines = <$ifh>;
    close $ifh;

    open(my $ofh, ">", $file) or die($ERRNO);
    foreach my $line (@lines) {
        if($line =~ /^use\ +(.+)\;/) {
            my $pragma = $1;
            if($pragma =~ /(strict|warnings|English|mro|diagnostics|Carp|Fatal|Array\:\:Contains)/ && $pragma !~ /Digest/) {
                # Remove this (old) lines
                next;
            }
            if($pragma =~ /(5.\d+)/ && $pragma !~ /Digest/) {
                # Always update the required perl version
                next;
            }
        }
        if($line =~ /^no\ if.*experimental\:\:smartmatch/) {
            next;
        }
        if($line =~ /^(our|my) \$VERSION/) {
            next;
        }

       if($line =~ /^\#\-\-\-AUTOPRAGMA/) {
           next;
       }

        print $ofh $line;

        if($inserted) {
            # Already inserted the pragmas
            next;
        }
        if($line =~ /^package\ / || $line =~ /^\#\!/) {
            print $ofh "#---AUTOPRAGMASTART---\n";
            print $ofh "use 5.010_001;\n";
            print $ofh "use strict;\n";
            print $ofh "use warnings;\n";
            print $ofh "use diagnostics;\n";
            print $ofh "use mro 'c3';\n";
            print $ofh "use English qw(-no_match_vars);\n";
            print $ofh "use Carp;\n";
            print $ofh "our \$VERSION = 6.0;\n";
            print $ofh "use Fatal qw( close );\n";
            print $ofh "use Array::Contains;\n";
            print $ofh "#---AUTOPRAGMAEND---\n";
            $inserted = 1;
        }
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
