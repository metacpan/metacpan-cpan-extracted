use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'News::Search',
    AUTHOR              => 'Tong Sun <suntong@cpan.org>',
    VERSION_FROM        => 'lib/News/Search.pm',
    ABSTRACT_FROM       => 'lib/News/Search.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    EXE_FILES		=> [ 'bin/news-search' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor::Fast' => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'Net::NNTP' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'News-Search-*' },
);
