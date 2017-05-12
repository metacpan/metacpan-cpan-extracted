use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Parse::Extract::Net::MAC48',
    'VERSION_FROM'      => 'MAC48.pm',
    'PREREQ_PM'         => {}, 
    ( 
        $] >= 5.005
          ? (ABSTRACT      => 'MAC48.pm',
             AUTHOR        => 'Charles A. Morris')
          : ()
    ),
);

