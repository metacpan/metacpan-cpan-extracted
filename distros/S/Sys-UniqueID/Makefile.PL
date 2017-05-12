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
  NAME	          => 'Sys::UniqueID',
  AUTHOR          => 'v (v@rant.scriptmania.com)',
  VERSION_FROM    => 'UniqueID.pm', 
  ABSTRACT_FROM   => 'UniqueID.pm',
  BINARY_LOCATION => 'Sys-UniqueID.ppm.tar.gz',
  PREREQ_PM       => 
  {
    'Sys::HostIP' => 0,
  },
  dist            => 
  {
    TAR      => 'C:\\progra~1\\util\\tar.exe',
    TARFLAGS => 'cvf',
    COMPRESS => 'C:\\progra~1\\util\\gzip.exe --best',
    SUFFIX   => '.gz',
  },
);
