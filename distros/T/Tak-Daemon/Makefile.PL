use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Tak::Daemon',
  VERSION_FROM => 'lib/Tak/Daemon.pm',
  PREREQ_PM => {
    'Tak' => '0.001002',
    'IO::Async' => '0.45'
  },
  LICENSE => 'perl',
  META_MERGE => {
     resources => {
         license     => 'http://dev.perl.org/licenses/',
         repository  => 'git://git.shadowcat.co.uk/scpubgit/Tak-Daemon.git',
     },
  }
);
