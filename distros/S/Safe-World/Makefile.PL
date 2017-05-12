###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Safe::World' ,
    'VERSION_FROM'  => 'lib/Safe/World.pm' ,
    'PREREQ_PM'     => {
      'Safe::Hole'  => 0.08 ,
      'Hash::NoRef' => 0.03 ,
    } ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Safe/World.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

