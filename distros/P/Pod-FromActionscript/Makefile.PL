use ExtUtils::MakeMaker;
WriteMakefile(
   'NAME'		=> 'Pod::FromActionscript',
   'VERSION_FROM'	=> 'lib/Pod/FromActionscript.pm',
   'PREREQ_PM'	=> {
      'Test::More'               => '0.01',
   },
   'EXE_FILES'       => ["script/asdoc2pod"],
   'PL_FILES'        => {},
   ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/Pod/FromActionscript.pm',
     AUTHOR     => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
);
