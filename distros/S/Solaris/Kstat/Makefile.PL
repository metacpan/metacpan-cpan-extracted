use ExtUtils::MakeMaker;
use Config;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.5.1|5.6|5.7)$/)
   {
   die("Solaris::Kstat is only supported on Solaris 2.5.1, 2.6 & 2.7\n");
   }

# 5.004_04 has a hv_delete that's broken
my $def;
if ($] < 5.00405)
   {
   print << "EOF";
ERROR: Your version of perl ($]) has a number of bugs that prevent this
       package from working.  If you want to use it you should upgrate to
       Perl 5.005_02 or above, or 5.004_05 when it becomes available - Sorry!
EOF
   exit(0);
   }

# I'll uncomment this after a few releases, but for now leave assertions in
# $def .= "-DNDEBUG ";

# Apparently gcc doesn't set the OS rel/ver macro, so we'll do it here
if ($Config{cc} =~ /gcc/)
   {
   if    ($rel eq "5.5.1") { $def .= "-D__SunOS_5_5_1 "; }
   elsif ($rel eq "5.6")   { $def .= "-D__SunOS_5_6 ";   }
   elsif ($rel eq "5.7")   { $def .= "-D__SunOS_5_7 ";   }
   }

WriteMakefile(
   NAME         => 'Solaris::Kstat',
   VERSION_FROM => 'Kstat.pm',
   LIBS         => [ '-lkstat' ],
   INC          => '-Iinclude',
   OBJECT       => '$(O_FILES)',
   DEFINE       => $def
   );
