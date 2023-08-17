#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.999_001';

use File::Find;
use File::Slurp;    ## no critic (DiscouragedModules)

use Test::More qw(no_plan);    ## no critic (ProhibitNoPlan)

my $last_version = undef;
find({ wanted => \&check_version, no_chdir => 1 }, 'lib');
if (!defined $last_version) {
    ## no critic (RequireInterpolationOfMetachars)
    fail('Failed to find any files with $VERSION');
    ## use critic
}                              # end if

sub check_version {

    # $_ is the full path to the file
    return if !m{blib/script/}xms && !m{ [.] pm \z}xms;

    my $content = read_file($_);

    # only look at perl scripts, not sh scripts
    return if m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms;

    my @version_lines = $content =~ m/ \s* ( [^\n]* \$VERSION \s* = \s* (?: eval \s* )? ['"]? \d+ [^\n]* ) /gxms;    # '
    if (@version_lines == 0) {
        fail($_);
    }    # end if
    foreach my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        } else {
            is($line, $last_version, $_);
        }    # end if
    }    # end foreach

    return;
}    # end check_version()
