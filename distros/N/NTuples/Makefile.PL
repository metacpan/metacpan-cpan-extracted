use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'NTuples',
    'VERSION_FROM'	=> 'NTuples.pm',
    'PREREQ_PM'		=> {}, 
    ( 
        $] >= 5.005
          ? (ABSTRACT   => 'Intra-Memory RDBMS',
             AUTHOR     => 'Charles A Morris')
          : ()
    ),
);
