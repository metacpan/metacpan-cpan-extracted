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

die("Program disabled, because it destroys POD on purpose. Enable program by commenting out this line!");

print "Searching files...\n";
my @files = (find_pm('lib'), find_pm('devscripts'));

print "Changing files:\n";
foreach my $file (@files) {
    if($file =~ /resetpod/) {
        print "Skipping my own program\n";
        next;
    }
    print "Editing $file...\n";

    my @lines;
    open(my $ifh, "<", $file) or die($ERRNO);
    @lines = <$ifh>;
    close $ifh;

    open(my $ofh, ">", $file) or die($ERRNO);
    my $packname = '';
    my @funcs;
    foreach my $line (@lines) {
        chomp $line;
        # Remove trailing whitespace
        $line =~ s/\ +$//g;
        $line =~ s/\t+$//g;
        print $ofh $line, "\n";

        # Now, for easier matching and stuff, also remove
        # leading whitespace...
        $line =~ s/^\ +//g;
        $line =~ s/^\t+//g;

        # ...and simplify whitespace in between
        $line =~ s/^\ +/ /g;
        $line =~ s/^\t+/ /g;

        if($line =~ /package\ (.*)\;/) {
            # Package name
            $packname = $1;
            next;
        }

        if($line =~ /sub\ (.*) \{/) {
            # Function
            push @funcs, $1;
            next;
        }

        if($line eq '1;') {
            # Found last line of perl program
            last;
        }
    }
    if($packname eq '') {
        print "****** No Package name in $file\n";
    }


my $header = <<"END_HEAD";
=head1 NAME

$packname - 

=head1 SYNOPSIS

  use $packname;
  
  

=head1 DESCRIPTION



END_HEAD

my $funcspod = '';
foreach my $func (@funcs) {
    $funcspod .= "=head2 $func\n\n\n\n";
}

my $footer = <<"END_FOOT";
=head1 IMPORTANT NOTE

This module is part of the PageCamel framework. Currently, only limited support
and documentation exists outside my DarkPAN repositories. This source is 
currently only provided for your reference and usage in other projects (just
copy&paste what you need, see license terms below).

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac\@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
END_FOOT

    print $ofh "__END__\n\n";
    print $ofh $header;
    print $ofh $funcspod;
    print $ofh $footer;


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
            #} elsif($fname =~ /\.p[lm]$/i && -f $fname) {
        } elsif($fname =~ /\.pm$/i && -f $fname) {
            push @files, $fname;
        }
    }
    closedir($dfh);
    return @files;
}
