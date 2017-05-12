use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Statistics::MaxEntropy', 
#    'PREREQ_PM' => {'Data::Dumper' => '2.09'},
    'VERSION_FROM' => 'MaxEntropy.pm', # finds $VERSION
    'dist'       => {'COMPRESS'  => 'gzip', 'SUFFIX' => 'gz'},
    'EXE_FILES' => [qw(ME.wrapper.pl)]
);
