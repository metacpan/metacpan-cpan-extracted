#!perl
use strict;
use warnings;
use v5.12;
use Config;

use ExtUtils::MakeMaker v6.46;

WriteMakefile
  (
   NAME => "PerlIO::win32console",
   VERSION_FROM => "win32console.pm",
   OBJECT => "win32console.o",
   LICENSE => "perl_5",
   AUTHOR => 'Tony Cook >tony@develop-help.com>',
   #CCFLAGS => "$Config{ccflags} -Wall -Wextra",
   ABSTRACT => 'Win32 console output layer',
   #
   META_MERGE =>
   {
    'meta-spec' =>
    {
     version => "2",
     url => "https://metacpan.org/pod/CPAN::Meta::Spec",
    },
    resources =>
    {
     homepage => "https://github.com/tonycoz/perlio-win32console",
     repository =>
     {
      type => "git",
      url => "https://github.com/tonycoz/perlio-win32console.git",
      web => "https://github.com/tonycoz/perlio-win32console",
     },
     bugtracker =>
     {
      web => "https://github.com/tonycoz/perlio-win32console.git",
     },
    },
   },
  )
