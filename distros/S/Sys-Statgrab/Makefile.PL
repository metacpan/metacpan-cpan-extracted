#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %PREREQ_PM = (
  'Unix::Statgrab' => 0.04,
);
$PREREQ_PM{'Win32::Process::Info'} = 1.006 if $^O eq 'MSWin32';

WriteMakefile (
 NAME		=> "Sys::Statgrab",
 AUTHOR		=> 'Eric Rybski (rybskej@yahoo.com)',
 ABSTRACT	=> 'Extension of Unix::Statgrab for greater portability',
 VERSION_FROM	=> 'lib/Sys/Statgrab.pm',
 PREREQ_PM	=> \%PREREQ_PM,
);
