use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

WriteMakefile(
    NAME                => 'Music::ChordBot',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/Music/ChordBot.pm',
    ABSTRACT_FROM       => 'lib/Music/ChordBot.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'parent' => 0,
	'JSON' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Music-ChordBot-*' },
);
