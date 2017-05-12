use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SOAP::Lite::InstanceExporter',
    'VERSION_FROM'	=> 'InstanceExporter.pm', # finds $VERSION
    'PREREQ_PM'		=> {'SOAP::Lite' => 0.47}, # highest tested version 
);
