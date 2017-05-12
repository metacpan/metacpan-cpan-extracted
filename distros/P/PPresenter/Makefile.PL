#!/usr/local/bin/perl -w
# Copyright (C) 2000-2002, Free Software Foundation FSF.

use ExtUtils::MakeMaker;
use English;

# Create the Makefile.

WriteMakefile
( NAME      => 'PPresenter'
, VERSION   => 'v1.17'
, AUTHOR    => 'Mark Overmeer'
, ABSTRACT  => 'Create presentations with Perl and Tk'
, PREREQ_PM => { "Tk"    => "800.012" }

, DIR       => [ qw/ppr xml/ ]
);

