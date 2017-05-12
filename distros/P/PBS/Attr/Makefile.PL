use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PBS::Attr',
    VERSION_FROM      => '../lib/PBS/Attr.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => '../lib/PBS/Attr.pm', # retrieve abstract from module
       AUTHOR         => 'system PRIVILEGED account <root@hpc.arizona.edu>') : ()),
    LIBS              => ['-L/usr/local/lib -lpbs'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/local/include', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw( MAXNAMLEN MAXPATHLEN MAX_ENCODE_BFR MGR_CMD_ACTIVE
		 MGR_CMD_CREATE MGR_CMD_DELETE MGR_CMD_LIST MGR_CMD_PRINT
		 MGR_CMD_SET MGR_CMD_UNSET MGR_OBJ_JOB MGR_OBJ_NODE
		 MGR_OBJ_NONE MGR_OBJ_QUEUE MGR_OBJ_SERVER MSG_ERR MSG_OUT
		 PBS_BATCH_SERVICE_PORT PBS_BATCH_SERVICE_PORT_DIS
		 PBS_INTERACTIVE PBS_MANAGER_SERVICE_PORT PBS_MAXCLTJOBID
		 PBS_MAXDEST PBS_MAXGRPN PBS_MAXHOSTNAME PBS_MAXPORTNUM
		 PBS_MAXQUEUENAME PBS_MAXROUTEDEST PBS_MAXSEQNUM
		 PBS_MAXSERVERNAME PBS_MAXSVRJOBID PBS_MAXUSER
		 PBS_MOM_SERVICE_PORT PBS_SCHEDULER_SERVICE_PORT
		 PBS_TERM_BUF_SZ PBS_TERM_CCA PBS_USE_IFF RESOURCE_T_ALL
		 RESOURCE_T_NULL SHUT_DELAY SHUT_IMMEDIATE SHUT_QUICK SHUT_SIG));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'PBS::Attr',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => '../const-c.inc',
                                     XS_FILE      => '../const-xs.inc',
                                  );

} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('../const-c.inc', '../const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
