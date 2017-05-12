use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

BEGIN {
       die "FATAL ERROR: this package will not work under Windows\n" if ($^O =~ /MSwin32/i);
       warn "WARNING: this package may not work properly under Cygwin\n" if ($^O =~ /cygwin/i);
      }

WriteMakefile(
    NAME              => 'Sudo',
    VERSION_FROM      => 'lib/Sudo.pm', # finds $VERSION
    PREREQ_PM         => {
			  Class::Accessor => 0.19 , 
			  IPC::Run => 0.79,
			  Term::ReadPassword	=> 0.06
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sudo.pm', # retrieve abstract from module
       AUTHOR         => 'Joe Landman <landman@scalableinformatics.com>') : ()),
);
