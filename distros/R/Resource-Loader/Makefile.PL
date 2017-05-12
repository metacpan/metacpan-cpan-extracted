use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Resource::Loader',
    'VERSION_FROM'	=> 'Loader.pm',
    'PREREQ_PM'		=> { Test::More	      => .44,
			     Test::Exception  => .15,
			   },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Loader.pm',
       AUTHOR     => 'Joshua Keroes <joshua@cpan.org>') : ()),
);
