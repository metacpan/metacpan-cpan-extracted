use ExtUtils::MakeMaker;

use 5.005;

WriteMakefile(
 'NAME'	      	 => 'Term::ANSIMenu',
 'VERSION_FROM'	 => 'ANSIMenu.pm',
 'PREREQ_PM'	   => {'Carp'          => 0,
                     'Term::ReadKey' => 0
                    },
 'ABSTRACT_FROM' => 'ANSIMenu.pm',
 'AUTHOR'        => 'J.A. de Vries <j.a.devries@dto.tudelft.nl>'
);

