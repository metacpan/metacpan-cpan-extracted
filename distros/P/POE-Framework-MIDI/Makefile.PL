use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

ExtUtils::Manifest::fullcheck();

WriteMakefile(
    NAME         => 'POE::Framework::MIDI',
    VERSION_FROM => 'lib/POE/Framework/MIDI.pm',
    ABSTRACT     => 'Algorithmic MIDI composition with POE',
    AUTHOR       => 'Steve McNabb <smcnabb@cpan.org>',
    PREREQ_PM    => {
        'POE'           => 0.29,
        'MIDI::Simple'  => 0,
        'Class::MethodMaker' => 0,
      #  'Music::Scales' => 0.05,
    },
);
