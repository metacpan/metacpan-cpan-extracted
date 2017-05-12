use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Religion::Bible::Regex::Builder',
    AUTHOR              => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    VERSION_FROM        => 'lib/Religion/Bible/Regex/Builder.pm',
    ABSTRACT_FROM       => 'lib/Religion/Bible/Regex/Builder.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'Perl::Critic' => 0,
      'YAML'       => 0,
      'Test::Deep' => 0,
      'Test::Base' => 0,
      'Test::Perl::Critic' => 0,
      'Test::More' => 0,
      'version'    => 0,
      'Religion::Bible::Regex::Config' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Religion-Bible-Regex-Builder-*' },
);
