use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Regexp::Log::BlueCoat',
    VERSION_FROM => 'lib/Regexp/Log/BlueCoat.pm',
    PREREQ_PM    => {
        'Test::More'  => 0,
        'Regexp::Log' => 0.01,
    },
    ABSTRACT_FROM => 'lib/Regexp/Log/BlueCoat.pm',
    AUTHOR        => "Philippe 'BooK' Bruhat <book\@cpan.org>",
);
