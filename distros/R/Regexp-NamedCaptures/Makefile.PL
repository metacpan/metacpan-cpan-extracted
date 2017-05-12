use ExtUtils::MakeMaker;
WriteMakefile
(
    AUTHOR => '"Joshua ben Jore" <jjore@cpan.org>',

    NAME => 'Regexp::NamedCaptures',
    ABSTRACT_FROM => 'lib/Regexp/NamedCaptures.pm',
    VERSION_FROM  => 'lib/Regexp/NamedCaptures.pm',
    PREREQ_PM => {
                  strict => 0,
                  warnings => 0,
                  Carp => 0,
                  Text::Balanced => 0,
                 },
);
