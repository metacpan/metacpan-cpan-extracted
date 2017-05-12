use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
  'NAME'         => 'News::Article::NoCeM',
  'DISTNAME'     => 'News-Article-NoCeM',
  'MAN3PODS'     => { 'NoCeM.pm' => '$(INST_MAN3DIR)/News::Article::NoCeM.3' },
  'VERSION_FROM' => 'NoCeM.pm',
  'PREREQ_PM'    => { 'News::Article' => 1.27, 'PGP::Sign' => 0.19 },
  'PM'           => { 'NoCeM.pm' => '$(INST_LIBDIR)/NoCeM.pm' },
  'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
