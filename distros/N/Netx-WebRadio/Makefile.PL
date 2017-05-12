use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Netx::WebRadio',
    VERSION_FROM => 'lib/Netx/WebRadio.pm', # finds $VERSION
    AUTHOR       => 'Nathanael Obermayer (natom-pause@smi2le.net)',
    ABSTRACT     => 'receive one or more webradio-stations',
    PREREQ_PM	 => { 'Class::MethodMaker' => 0 },
);
