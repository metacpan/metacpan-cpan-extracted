use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Parliament',
    AUTHOR        => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM  => 'lib/Net/Parliament.pm',
    ABSTRACT_FROM => 'lib/Net/Parliament.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'Moose'              => 0,
        'HTML::TableExtract' => 0,
        'XML::Simple'        => 0,
        'HTML::TreeBuilder'  => 0,
        'IO::All'            => 0,
        'HTML::ElementTable' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-Parliament-* cache/*' },
);
