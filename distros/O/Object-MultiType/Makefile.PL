###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Object::MultiType' ,
    'VERSION_FROM'	=> 'MultiType.pm' ,
    'PREREQ_PM'		=> {} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'MultiType.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;

