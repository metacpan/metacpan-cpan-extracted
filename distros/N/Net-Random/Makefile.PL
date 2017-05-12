# $Id: Makefile.PL,v 1.3 2007/03/16 15:34:34 drhyde Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Net::Random',
  META_MERGE => {
    license => 'other',
    resources => {
      repository => {
        web => 'https://github.com/DrHyde/perl-modules-Net-Random'
      },
      bugtracker => {
        web => 'https://github.com/DrHyde/perl-modules-Net-Random/issues/new'
      },
    },
  },
  VERSION_FROM => 'lib/Net/Random.pm',
  PREREQ_PM => {
    'LWP::UserAgent'   => 0,
    'Encode::Locale'   => 1.01, # dep of LWP; earlier versions emit
                                # spurious warnings
    'Test::More'       => 0.64,
    'Test::MockObject' => 1.07,
    'JSON'             => 2.90,
  }
);
