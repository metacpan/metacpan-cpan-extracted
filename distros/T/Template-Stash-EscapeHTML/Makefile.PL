use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Stash::EscapeHTML',
    AUTHOR              => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    VERSION_FROM        => 'lib/Template/Stash/EscapeHTML.pm',
    ABSTRACT_FROM       => 'lib/Template/Stash/EscapeHTML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        Template => 2.13
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Stash-EscapeHTML-*' },
);
