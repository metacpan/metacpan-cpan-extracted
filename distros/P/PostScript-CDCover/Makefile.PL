use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'PostScript::CDCover',
    VERSION_FROM => 'lib/PostScript/CDCover.pm',
    ABSTRACT_FROM => 'lib/PostScript/CDCover.pm',
    AUTHOR => 'Cédric Bouvier <cbouvi@cpan.org>',
    EXE_FILES => [ 'bin/pscdcover' ],
);
