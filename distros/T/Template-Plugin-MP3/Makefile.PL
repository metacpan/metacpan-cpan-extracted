#!/usr/bin/perl

# ----------------------------------------------------------------------
# $Id: Makefile.PL,v 1.1.1.1 2003/06/24 13:42:29 dlc Exp $
# ----------------------------------------------------------------------

use strict;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'MP3::Info' => 1.01,
    'Template'  => 2.08,
);

my %clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

my %dist = (
    PREOP => 'perldoc -t MP3.pm > README; cpansign -s',
);


WriteMakefile(
    NAME         => "Template::Plugin::MP3",
    VERSION_FROM => "MP3.pm",
    PREREQ_PM    => \%PREREQ_PM,
    clean        => \%clean,
    dist         => \%dist,
);

package MY;
use File::Basename qw(basename);

sub libscan {
    my $self = shift;
    my $file = shift;
    my $bfile = basename $file;

    return if $bfile =~ m#^(TAGS|tags)$#;
    return if $bfile =~ m#^\.#;
    return if $bfile =~ m#~$#;
    return $file;
}

