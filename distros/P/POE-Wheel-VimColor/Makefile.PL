use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'POE::Wheel::VimColor',
    ABSTRACT => 'A POE Wheel for Text::VimColor',
    AUTHOR => 'Matthew O\'Connor <matthew@canonical.org>',
    VERSION => '0.01',
    PREREQ_FATAL => 1,
    PREREQ_PM => {
        POE => 0.33,
        'Text::VimColor' => 0.11,
        'Test::More' => 0.62
    },
);
