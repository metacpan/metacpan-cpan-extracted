use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Flow',
    AUTHOR              => q{Daniel Perrett <perrettdl@googlemail.com>},
    VERSION_FROM        => 'lib/Regexp/Flow.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Flow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
	META_MERGE    => {
                resources => {
                        repository => 'http://github.com/pdl/Regexp-Flow',
                        bugtracker => 'http://github.com/pdl/Regexp-Flow/issues',
                        homepage   => 'http://github.com/pdl/Regexp-Flow',
                },
        },
    MIN_PERL_VERSION    => '5.010',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.96,
	'Regexp::Result' => '0.002',
	'Moo' => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Flow-*' },
);
