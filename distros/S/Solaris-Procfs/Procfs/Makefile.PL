use ExtUtils::MakeMaker;
use Config;
use POSIX qw(uname);

# Check this is a supported OS release
#
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.6|5.7|5.8|5.9)$/) {

   die("Solaris::Procfs is only supported on Solaris 2.6, 7, 8, or 9\n");
}


# Apparently gcc doesn't set the OS rel/ver macro, so we'll do it here
#
if ($Config{cc} =~ /gcc/) {

   if    ($rel eq "5.5.1") { $def .= "-D__SunOS_5_5_1 "; }
   elsif ($rel eq "5.6")   { $def .= "-D__SunOS_5_6 ";   }
   elsif ($rel eq "5.7")   { $def .= "-D__SunOS_5_7 ";   }
   elsif ($rel eq "5.8")   { $def .= "-D__SunOS_5_8 ";   }
   elsif ($rel eq "5.9")   { $def .= "-D__SunOS_5_9 ";   }
}


# The procfs.h header file requires that file_offset_bits be
# set to 32 rather than 64.  Perl 5.6.x sets this flag to 64.
# We redefine it here, and this generates a warning, but it also
# allows us to build the library. 
#
$def .= "-D_FILE_OFFSET_BITS=32 ";


WriteMakefile(
   NAME         => 'Solaris::Procfs',
   VERSION_FROM => 'Procfs.pm',
   PM		=> {
			'Procfs.pm' =>     '$(INST_LIBDIR)/Procfs.pm',
			'Process.pm' =>    '$(INST_LIBDIR)/Procfs/Process.pm',
			'Filesystem.pm' => '$(INST_LIBDIR)/Procfs/Filesystem.pm',
			'procfs.ph' =>     '$(INST_LIBDIR)/Procfs/include/sys/procfs.ph'
		},
   LIBS         => [ '' ],
   INC          => '-Iinclude',
   OBJECT       => '$(O_FILES)',
   DEFINE       => $def,
);

