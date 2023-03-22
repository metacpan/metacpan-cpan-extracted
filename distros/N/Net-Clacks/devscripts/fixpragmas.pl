#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 27;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

# PAGECAMEL  (C) 2008-2023 Rene Schickbauer
# Developed under Artistic license


print "Searching files...\n";
my @files = (find_pm('lib'), find_pm('devscripts'), find_pm('example'));
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
            if($pragma =~ /(strict|warnings|English|mro|diagnostics|Carp|Fatal|Array\:\:Contains|autodie|utf8|Encode|Data\:\:Dumper|builtin)/ && $pragma !~ /Digest/) {
                # Remove this (old) lines
                next;
            }
            if($pragma =~ /(5\.\d+)/ && $pragma !~ /Digest/) {
                # Always update the required perl version
                next;
            }
        }
        if($line =~ /^no\ if.*experimental\:\:smartmatch/) {
            next;
        }
        if($line =~ /^use\ English\ qw/) {
            next;
        }
        if($line =~ /^(our|my) \$VERSION/) {
            next;
        }

        # Handle sub "signatures"
        if($line =~ /^use\ feature\ \'signatures\'/ || $line =~ /^no\ warnings\ .*experimental\:\:signatures/) {
            next;
        }
        # Handle the new "builtin" stuff
        if($line =~ /^no\ warnings\ .*experimental\:\:builtin/) {
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
            print $ofh "use v5.36;\n";
            print $ofh "use strict;\n";
            print $ofh "use diagnostics;\n";
            print $ofh "use mro 'c3';\n";
            print $ofh "use English qw(-no_match_vars);\n";
            print $ofh "use Carp qw[carp croak confess cluck longmess shortmess];\n";
            print $ofh "our \$VERSION = 27;\n";
            print $ofh "use autodie qw( close );\n";
            print $ofh "use Array::Contains;\n";
            print $ofh "use utf8;\n";
            print $ofh "use Encode qw(is_utf8 encode_utf8 decode_utf8);\n";
            print $ofh "use Data::Dumper;\n";
            print $ofh "use builtin qw[true false is_bool];\n";
            print $ofh "no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)\n";
            print $ofh "#---AUTOPRAGMAEND---\n";
            $inserted = 1;
        }
    }
    close $ofh;
}
print "Done.\n";
exit(0);



sub find_pm($workDir) {
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
