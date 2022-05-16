#!/usr/bin/env perl 
#===============================================================================
#         FILE: samples2config.pl
#        USAGE: ./samples2config.pl  
#  DESCRIPTION:generate Sys::OsRelease unit test configuration file from sample files
#       AUTHOR: Ian Kluft (IKLUFT)
#      CREATED: 04/25/2022 09:54:44 PM
#===============================================================================

use strict;
use warnings;
use utf8;
use Carp qw(croak);
use Cwd;
use YAML;

# fold case for case-insensitive matching (copy of Sys::OsRelease::fold_case)
my $can_fc = CORE->can("fc"); # test fc() once and save result
sub fold_case
{
    my $str = shift;

    # use fc if available, otherwise lc to support older Perls
    return $can_fc ?  $can_fc->($str) : lc($str);
}

#
# mainline
#

# find sample files
my @samples;
my $dir = getcwd();
{
    opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
    @samples = grep { /^os-release-/ && -f "$dir/$_" } readdir($dh);
    closedir $dh;
}

# give up if none found (probably running in wrong directory)
if (scalar @samples == 0) {
    croak "No sample files found. Is this in the correct directory?";
}

# start constructing test data configuration structure
my %config;
my $count = 0;
$config{files} = {};
foreach my $sample (@samples) {
    my %tests;
    
    # each entry in the sample os-release becomes a test case
    open my $fh, "<", $dir."/".$sample
        or croak "failed to open $sample: $!";
    while (my $line = <$fh>) {
        chomp $line; # remove trailing cr/nl
        if (substr($line, -1, 1) eq "\r") {
            $line = substr($line, 0, -1); # remove trailing cr
        }

        # skip comments and blank lines
        if ($line =~ /^ \s+ #/x or $line =~ /^ \s+ $/x) {
            next;
        }

        # read attribute assignment lines
        if ($line =~ /^ ([A-Z0-9_]+) = "(.*)" $/x
            or $line =~ /^ ([A-Z0-9_]+) = '(.*)' $/x
            or $line =~ /^ ([A-Z0-9_]+) = (.*) $/x)
        {
            next if $1 eq "config"; # don't overwrite config
            $tests{fold_case($1)} = $2;
        }
        # skip if pattern not recognized
    }
    close $fh;

    # save the tests for this file
    $config{files}{$sample} = \%tests;
    $count += 3*(scalar keys %tests)+2;
}
$config{count} = $count;

# write the config data
print YAML::Dump(\%config);
