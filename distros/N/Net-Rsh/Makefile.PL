use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Rsh',
    'VERSION_FROM'	=> 'Rsh.pm',
    'PREREQ_PM'		=> { 'IO::Socket' => 0 , 'Errno' => 0 }, 
    'dist'		=> { 'COMPRESS' => 'gzip','SUFFIX'   => 'gz' }
);
