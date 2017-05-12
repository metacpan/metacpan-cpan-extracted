use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Sys::Load',
    'VERSION_FROM'	=> 'Load.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Load.pm',
       AUTHOR        => 'Peter BARABAS <z0d [@] artifact [.] hu>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '',
);

