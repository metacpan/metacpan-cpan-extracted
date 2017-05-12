use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::DataHash',
    'VERSION_FROM'	=> 'DataHash.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DataHash.pm', # retrieve abstract from module
       AUTHOR     => 'earl@cpan.org') : ()),
);

sub postamble {
  return qq^
    
pm_to_blib: README

README: DataHash.pm
\tpod2text DataHash.pm >README
  ^;
}
