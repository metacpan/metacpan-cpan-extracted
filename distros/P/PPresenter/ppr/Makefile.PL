#!/usr/local/bin/perl -w
# Copyright (C) 2000-2002, Free Software Foundation FSF.

use ExtUtils::MakeMaker;
use English;

# Excutables
# On M$ Windows, binaries are limited in length of name and require
# an extentions to indicate which interpreter is to be run.  On UNIX
# I dislike this practice: let us rename the file if is run on systems
# other than UNIX.

my $bins;
if($OSNAME =~ /^win/i )
{   rename 'present', 'present.pl';
    rename 'present-ppr', 'ppppr.pl';
    $bins = [ qw(bin/present.pl bin/ppppr.pl) ];
}
else
{   $bins = [ qw(present present-ppr) ];
}

# Create the Makefile.

WriteMakefile
( NAME      => 'PPresenter - PPR'
, VERSION   => 'v1.17'
, AUTHOR    => 'Mark Overmeer'

, EXE_FILES => $bins
);

