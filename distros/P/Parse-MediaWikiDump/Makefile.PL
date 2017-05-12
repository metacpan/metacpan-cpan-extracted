use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'Parse::MediaWikiDump',
    AUTHOR              => 'Tyler Riddle <triddle@gmail.com>',
    VERSION_FROM        => 'lib/Parse/MediaWikiDump.pm',
    ABSTRACT_FROM       => 'lib/Parse/MediaWikiDump.pm',
    PL_FILES            => {},
    PREREQ_PM => {
    'PadWalker' => '1.9',
    'Devel::Cycle' => '1.11',
    'Test::Memory::Cycle' => '1.04',
    'Test::More' => '0.94',
    'Test::Exception' => '0.27',
    'Test::Warn' => '0.21',
    'XML::Parser' => '2.36',
    'List::Util' => '1.21',
    'Scalar::Util' => '1.21',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-MediaWikiDump-*' },
);
