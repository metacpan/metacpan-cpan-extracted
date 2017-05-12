use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Taint::Runtime',
  VERSION_FROM  => 'lib/Taint/Runtime.pm',
  ABSTRACT_FROM => 'lib/Taint/Runtime.pm',
  AUTHOR        => 'Paul Seamons',
);

package MY;

sub postamble {
  return qq^

pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}
