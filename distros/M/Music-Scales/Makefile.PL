use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Music::Scales',
    VERSION_FROM => 'lib/Music/Scales.pm', # finds $VERSION
    AUTHOR       => 'Ben Daglish (bdaglish@surfnet-ds.co.uk)',
    ABSTRACT     => 'Generate musical scales',
);
