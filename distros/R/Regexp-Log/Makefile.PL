use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Regexp::Log',
    VERSION_FROM  => 'lib/Regexp/Log.pm',
    PREREQ_PM     => { 'Test::More' => 0 },
    ABSTRACT_FROM => 'lib/Regexp/Log.pm',
    AUTHOR        => "Philippe 'BooK' Bruhat <book\@cpan.org>",
    PL_FILES      => {},
);
