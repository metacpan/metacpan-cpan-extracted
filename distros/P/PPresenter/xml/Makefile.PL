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
{   rename 'present-xml', 'ppxml.pl';
    $bins = [ qw(ppxml.pl) ];
}
else
{   $bins = [ qw(present-xml) ];
}

# Create the Makefile.

WriteMakefile
( NAME      => 'PPresenter - XML'
, VERSION   => 'v1.17'
, AUTHOR    => 'Johan Vromans'

, EXE_FILES => $bins
);

