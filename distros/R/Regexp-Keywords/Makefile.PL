use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Keywords',
    AUTHOR              => q{Victor Parada <vitoco@cpan.org>},
    VERSION_FROM        => 'lib/Regexp/Keywords.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Keywords.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Keywords-*' },
);
