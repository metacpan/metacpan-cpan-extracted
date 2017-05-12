#!/usr/bin/perl

# ----------------------------------------------------------------------
# $Id: Makefile.PL,v 1.1.1.1 2004/10/08 13:38:07 dlc Exp $
# ----------------------------------------------------------------------
# Makefile.PL for Jiva
# Originally created on Tuesday, March 23, 2004
# ----------------------------------------------------------------------

use strict;

use ExtUtils::MakeMaker;
my (%PREREQ_PM, @EXE_FILES, %clean, %macro, %dist, @AUTHOR, @ABSTRACT, @SIGN);

%PREREQ_PM = (
    'GnuPG'                     => 0.09,
    'Template::Plugin::Filter'  => 0.00,
);

@EXE_FILES = ();

%clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

%macro = ( );

%dist = ( );

if ($ExtUtils::MakeMaker::VERSION > 6.06) {
    @AUTHOR = (AUTHOR => 'darren chamberlain <darren@cpan.org>');
    @ABSTRACT = (ABSTRACT => '');
}
else {
    @AUTHOR = ();
    @ABSTRACT = ();
}

if ($ExtUtils::MakeMaker::VERSION >= 6.18) {
    @SIGN = (SIGN => 1);
}
else {
    @SIGN = ();
}

WriteMakefile(
    NAME        => "Template::Plugin::GnuPG",
    VERSION     => "0.01",
    PREREQ_PM   => \%PREREQ_PM,
    EXE_FILES   => \@EXE_FILES,
    clean       => \%clean,
    macro       => \%macro,
    dist        => \%dist,
    @SIGN,
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
