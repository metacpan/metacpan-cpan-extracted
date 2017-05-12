use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Statistics::Cluto',
    VERSION_FROM      => 'lib/Statistics/Cluto.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Statistics/Cluto.pm', # retrieve abstract from module
       AUTHOR         => '<tsukue@gmail.com>') : ()),
    LIBS              => ['-lcluto '], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CLUTO_CLFUN_CLINK CLUTO_CLFUN_CLINK_W CLUTO_CLFUN_CUT
		 CLUTO_CLFUN_E1 CLUTO_CLFUN_G1 CLUTO_CLFUN_G1P CLUTO_CLFUN_H1
		 CLUTO_CLFUN_H2 CLUTO_CLFUN_I1 CLUTO_CLFUN_I2 CLUTO_CLFUN_MMCUT
		 CLUTO_CLFUN_NCUT CLUTO_CLFUN_RCUT CLUTO_CLFUN_SLINK
		 CLUTO_CLFUN_SLINK_W CLUTO_CLFUN_UPGMA CLUTO_CLFUN_UPGMA_W
		 CLUTO_COLMODEL_IDF CLUTO_COLMODEL_NONE CLUTO_CSTYPE_BESTFIRST
		 CLUTO_CSTYPE_LARGEFIRST CLUTO_CSTYPE_LARGESUBSPACEFIRST
		 CLUTO_DBG_APROGRESS CLUTO_DBG_CCMPSTAT CLUTO_DBG_CPROGRESS
		 CLUTO_DBG_MPROGRESS CLUTO_DBG_PROGRESS CLUTO_DBG_RPROGRESS
		 CLUTO_GRMODEL_ASYMETRIC_DIRECT CLUTO_GRMODEL_ASYMETRIC_LINKS
		 CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
		 CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
		 CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
		 CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
		 CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
		 CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
		 CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
		 CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS CLUTO_GRMODEL_NONE
		 CLUTO_GRMODEL_SYMETRIC_DIRECT CLUTO_GRMODEL_SYMETRIC_LINKS
		 CLUTO_MEM_NOREUSE CLUTO_MEM_REUSE CLUTO_MTYPE_HEDGE
		 CLUTO_MTYPE_HSTAR CLUTO_MTYPE_HSTAR2
		 CLUTO_OPTIMIZER_MULTILEVEL CLUTO_OPTIMIZER_SINGLELEVEL
		 CLUTO_ROWMODEL_LOG CLUTO_ROWMODEL_MAXTF CLUTO_ROWMODEL_NONE
		 CLUTO_ROWMODEL_SQRT CLUTO_SIM_CORRCOEF CLUTO_SIM_COSINE
		 CLUTO_SIM_EDISTANCE CLUTO_SIM_EJACCARD
		 CLUTO_SUMMTYPE_MAXCLIQUES CLUTO_SUMMTYPE_MAXITEMSETS
		 CLUTO_TREE_FULL CLUTO_TREE_TOP CLUTO_VER_MAJOR CLUTO_VER_MINOR
		 CLUTO_VER_SUBMINOR));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Statistics::Cluto',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
