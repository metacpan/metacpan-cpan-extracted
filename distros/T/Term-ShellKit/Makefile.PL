use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'	=> 'Term::ShellKit',
  VERSION_FROM	=> "ShellKit.pm",
  PREREQ_PM	=> {},
  ($] >= 5.005 ? (
    ABSTRACT_FROM => 'ShellKit.pm', 
    AUTHOR     => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
  ) : ()),
);
sub MY::postamble { q{

docs : README CHANGES TODO

README: ShellKit/ReadMe.pod
	pod2text ShellKit/ReadMe.pod > README

CHANGES: ShellKit/Changes.pod
	pod2text ShellKit/Changes.pod > CHANGES

TODO: ShellKit/ToDo.pod
	pod2text ShellKit/ToDo.pod > TODO

cleanmanifest:
	rm MANIFEST ; touch MANIFEST; make manifest

}; }
