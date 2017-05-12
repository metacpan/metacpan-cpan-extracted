use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Proc::Reliable',
    'VERSION_FROM'   => 'Reliable.pm',
    'dist'      => {'COMPRESS'=>'gzip -f', 'SUFFIX' => 'gz'}
);

