
use utf8;
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME               => 'Search::ByPrefix',
              AUTHOR             => q<Daniel Șuteu <trizen@cpan.org>>,,
              VERSION_FROM       => 'lib/Search/ByPrefix.pm',
              ABSTRACT_FROM      => 'lib/Search/ByPrefix.pm',
              LICENSE            => 'artistic_2',
              PL_FILES           => {},
              MIN_PERL_VERSION   => 5.010,
              CONFIGURE_REQUIRES => {
                                     'ExtUtils::MakeMaker' => 0,
                                    },
              BUILD_REQUIRES => {
                                 'Test::More' => 0,
                                },
              PREREQ_PM  => {},
              META_MERGE => {
                             resources => {
                                           repository => 'https://github.com/trizen/Search-ByPrefix',
                                          },
                            },
              dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
              clean => {FILES    => 'Search-ByPrefix-*'},
             );
