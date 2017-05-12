use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Quilt',
    'VERSION_FROM' => 'lib/Quilt.pm',
    clean       => {'FILES' => '*/*/*/*~'},
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
