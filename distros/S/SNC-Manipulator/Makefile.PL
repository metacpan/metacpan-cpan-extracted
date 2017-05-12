use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SNC::Manipulator',
    'VERSION_FROM'	=> 'Manipulator.pm',
    'PREREQ_PM'		=> {}, 
    ( 
        $] >= 5.005
          ? (ABSTRACT_FROM => 'Manipulator.pm',
             AUTHOR        => 'Charles A Morris')
          : ()
    ),
);
