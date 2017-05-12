use ExtUtils::MakeMaker;

sub MY::postamble { <<'.'; }

dist_both : dist ppmdist 

ppmdist : ppd pure_all
	$(TAR) $(TARFLAGS) $(DISTNAME).ppm.tar blib
	$(RM_RF) blib
	$(RM_RF) pm_to_blib
	$(COMPRESS) $(DISTNAME).ppm.tar
.

WriteMakefile(
  NAME	          => 'PostScript::Columns',
  AUTHOR          => 'v (v@rant.scriptmania.com)',
  VERSION_FROM    => 'Columns.pm', 
  ABSTRACT_FROM   => 'Columns.pm',
  BINARY_LOCATION => 'PostScript-Columns.ppm.tar.gz',
  PREREQ_PM       => 
  {
    'POSIX'  => 0,
  },
  dist            => 
  {
    TAR      => 'C:\\progra~1\\util\\tar.exe',
    TARFLAGS => 'cvf',
    COMPRESS => 'C:\\progra~1\\util\\gzip.exe --best',
    SUFFIX   => '.gz',
  },
);
