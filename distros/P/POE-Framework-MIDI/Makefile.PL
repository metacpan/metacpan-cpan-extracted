use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

ExtUtils::Manifest::fullcheck();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'POE::Framework::MIDI',
    VERSION_FROM => 'lib/POE/Framework/MIDI/Conductor.pm', # finds $VERSION
    AUTHOR       => 'Steve McNabb (steve@justsomeguy.com)',
    ABSTRACT     => 'A framework for algorithmic composition using POE'
);
