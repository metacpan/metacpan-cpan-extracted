use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
{
   use strict;
   use Config;
   use Carp;
   sub vcheck {
      croak "unsupported platform: $Config::Config{osname}/$Config::Config{osvers}\n"
	 unless $Config::Config{osname} eq 'solaris';
   }
   sub is64bit {
      return qx(/usr/bin/isainfo -b) =~ /64/
         if ($Config::Config{osvers} >= 2.5);
      return qx(/bin/file $Config::Config{bin}/perl) =~ /64/;
   }
}

WriteMakefile(
    'NAME'		=> 'Solaris::Kvm',
    'VERSION_FROM'	=> 'Kvm.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Kvm.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
    'LIBS'		=> ['-lkvm -lelf'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'CONFIGURE'         => 
       sub {
	  vcheck();
	  return { 'CCFLAGS'   => '-m64 -mcpu=v9',
		   'LDDLFLAGS' => '-m64 -mcpu=v9 -G -L/usr/local/lib -L/usr/lib/sparcv9'
                 } if is64bit();
       },
);
