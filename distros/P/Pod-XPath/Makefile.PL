#!/usr/bin/perl

# ----------------------------------------------------------------------
# $Id: Makefile.PL,v 1.3 2003/09/12 16:04:35 dlc Exp $
# ----------------------------------------------------------------------
# Makefile.PL for Pod::XPath.
# Originally created on Thursday, July 10, 2003.
# ----------------------------------------------------------------------

use strict;

use ExtUtils::MakeMaker;
my (%PREREQ_PM, @EXE_FILES, %clean, %macro, %dist, @AUTHOR, @ABSTRACT);

%PREREQ_PM = (
    'Pod::XML'              => 0,
    'IO::String'            => 0,
    'XML::XPath'            => 0,
    'UNIVERSAL::require'    => 0,
);

@EXE_FILES = (

);

%clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

%macro = (

);

%dist = (
    PREOP => 'perldoc -t lib/Pod/XPath.pm > README; cpansign -s',
);

if ($] >= 5.00503) {
    @AUTHOR = (AUTHOR => 'darren chamberlain <darren@cpan.org>');
    @ABSTRACT = (ABSTRACT => '');
}
else {
    @AUTHOR = ();
    @ABSTRACT = ();
}

WriteMakefile(
    NAME        => "Pod::XPath",
    VERSION     => "1.00",
    PREREQ_PM   => \%PREREQ_PM,
    EXE_FILES   => \@EXE_FILES,
    clean       => \%clean,
    macro       => \%macro,
    dist        => \%dist,
    @AUTHOR,
    @ABSTRACT,
);

package MY;
use File::Basename qw(basename);

sub libscan {
    my ($self, $file) = @_;
    my $bfile = basename($file);

    return if $bfile =~ /^\.(?:cvs)?ignore$/;
    return if $bfile =~ /\.swp$/;

    return $self->SUPER::libscan($file);
}
