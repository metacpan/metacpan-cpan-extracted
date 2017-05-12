use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PCL::Simple',
    'VERSION_FROM'	=> 'Simple.pm',
    'PREREQ_PM'		=> {}, 
    ( 
        $] >= 5.005
          ? (ABSTRACT_FROM => 'Simple.pm',
             AUTHOR        => 'Phil R Lawrence')
          : ()
    ),
);
