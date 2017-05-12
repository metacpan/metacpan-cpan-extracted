use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;
use Data::Dumper;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Ensure deterministic output
$Data::Dumper::Sortkeys = 1;

# Supported windowing interfaces
our $is_valid_interface =
{
  'AGL'       => 'Default GLUT framework on Mac OS X',
  'FREEGLUT'  => 'FreeGLUT, preferred over GLUT',
  'GLUT'      => 'GLUT; often really FreeGLUT on Linux',
};


# Makefile.PL Usage
sub Usage
{
  print "\n@_\n\n";

  print qq
  {
    USAGE: perl Makefile.PL [OPTIONS]


    OPTIONS include:

    help                This help message

    verbose             Display additional status info, can be
                        repeated for more verbosity

    dist=NO_EXCLUSIONS  Build with no OpenGL Extension exclusions

    interface=XFACE     Build for a specific windowing interface
                        Currently supports:
  };

  print "\n";
  foreach my $xface (sort keys %$is_valid_interface)
  {
    print substr("      $xface                  ",0,24).
      "$is_valid_interface->{$xface}\n";
  }
  print "\n";
  exit(0);
}
if (@ARGV and $ARGV[0] =~ m|^([-/]*)?h(elp)?|i)
{
  Usage();
}
else
{
  print "\nrun as `perl Makefile.PL help` to show user options\n";
}

our $verbose = 0;
our $IS_MINGW = 0;
our $IS_STRAWBERRY = 0;
our $IS_CYGWIN;
our $IS_W32API;
my $INCS;

my $prepare_success = eval {

# Get debugging flags
if ( grep { if (m/^verbose/i) { $verbose++; 1; } else { 0; } } @ARGV )
{
  # Strip out interface args
  @ARGV = grep { !m/^verbose=/i } @ARGV;
}
print "\$verbose set to $verbose" . ($verbose ? "" : " - enable by running as `perl Makefile.PL verbose`");
print "\n\n";


# Get distribution build flags
our $dist_flags = {};
if ( grep { m/^dist=/i } @ARGV )
{
  foreach my $arg (@ARGV)
  {
    $dist_flags->{uc($1)}++ if ($arg =~ m/^dist=(\w+)/i);
  }

  # Strip out interface args
  @ARGV = grep { !m/^dist=/i } @ARGV;
}


# Detect CYGWIN
$IS_CYGWIN = $^O eq 'cygwin';
print "Build platform \$IS_CYGWIN==$IS_CYGWIN\n" if $IS_CYGWIN and $verbose;

$IS_W32API = ($IS_CYGWIN && grep { m/^interface=(W32API|WGL)/i } @ARGV );
print "Build platform \$IS_W32API==$IS_W32API\n" if $IS_W32API and $verbose;


# Detect MINGW
if ($^O eq 'MSWin32' && $Config{cc} =~ /\bgcc/i)
{
  $IS_MINGW = 1;
  print "Build platform \$IS_MINGW==1" if  $verbose;
}


# Detect Strawberry Perl
if ($IS_MINGW)
{
  $IS_STRAWBERRY = ($Config{cf_by} =~ m/strawberry-perl/i);
  print "Build platform \$IS_STRAWBERRY==$IS_STRAWBERRY\n" if $IS_STRAWBERRY and $verbose;
}


# Look for available libs
our @libdirs = qw
{
  -L/usr/lib
  -L/usr/lib/i386-linux-gnu
  -L/usr/X11R6/lib
  -L/opt/X11/lib
  -L/usr/local/lib
  -L/usr/openwin/lib
  -L/opt/csw/lib
  -L/usr/local/freeglut/lib
};

our @check_libs = qw
{
  -lGL
  -lopengl
  -lMesaGL
  -lGLU
  -lglu
  -lMesaGLU
  -lfreeglut
  -lglut3
  -lglut
  -lGLUT
  -lMesaGLUT
};

our $found_libs = get_libs(@libdirs,@check_libs);
die "No OpenGL related libs found\n" if (!scalar($found_libs));

if ($verbose)
{
  print "found libs:\n";
  foreach my $key (sort keys %$found_libs)
  {
    print "    $key = '$found_libs->{$key}'\n";
  }
}

# Check for OpenGL installation
our $DIST_DEFS = get_extensions($found_libs,$dist_flags->{NO_EXCLUSIONS});

# Don't build Makefile if we cannot compile+run glversion
die "unable to determine extensions or no extensions found\n" if !length $DIST_DEFS;

# Get user-specified interface
my $interface_lib;
if ( grep { m/^interface=/i } @ARGV )
{
  my @my_argv = @ARGV;    # safe copy
  my @interface_opts = ();
  my $fallback = 0;

  foreach my $arg (@my_argv)
  {
    if ($arg =~ m/^interface=(\w+)/i)
    {
      my $interface = uc($1);
      my $valid_type = $is_valid_interface->{$interface};
      if (!$valid_type)
      {
        Usage("Invalid interface: '$interface'");
        next;
      }

      # test if requested interfaces supported
      # !!! Should use lookup table
      if ($interface eq 'W32API' or $interface eq 'WGL')
      {
        if (!$found_libs->{FREEGLUT32} && !$found_libs->{GLUT32})
        {
          print "W32API interface requires GLUT or FreeGLUT\n";
          next;
        }
        if (!$found_libs->{OPENGL32})
        {
          print "W32API interface requires OpenGL32.dll\n";
          next;
        }
        if (!$found_libs->{GLU32})
        {
          print "W32API interface requires GLU32.dll\n";
          next;
        }
      }
      elsif ($interface eq 'AGL')
      {
        if ($^O ne 'darwin' || !$found_libs->{GLUT})
        {
          print "AGL interface requires GLUT.framework\n";
          next;
        }
      }
      elsif ($interface =~ m|GLUT|)
      {
        if ($interface eq 'FREEGLUT')
        {
          if (!$found_libs->{FREEGLUT} && !$found_libs->{FREEGLUT32})
          {
            print "FREEGLUT interface requires FreeGLUT\n";

            if ($found_libs->{GLUT})
            {
              print "Falling back to the GLUT interface\n";
              $interface = 'GLUT';
              $fallback++;
            }
            else
            {
              print "Try installing FREEGLUT first\n";
              next;
            }
          }
        }
        elsif ($interface eq 'GLUT')
        {
          if (!$found_libs->{GLUT} && $found_libs->{FREEGLUT})
          {
            $found_libs->{GLUT} = $found_libs->{FREEGLUT};
          }

          if (!$found_libs->{GLUT32} && $found_libs->{FREEGLUT32})
          {
            $found_libs->{GLUT32} = $found_libs->{FREEGLUT32};
          }

          if ($found_libs->{GLUT})
          {
            delete($found_libs->{FREEGLUT});
          }

          if ($found_libs->{GLUT32})
          {
            delete($found_libs->{FREEGLUT32});
          }

          if (!$found_libs->{GLUT} && !$found_libs->{GLUT32})
          {
            print "GLUT interface requires GLUT or FreeGLUT but libs were not found\n";
            next;
          }
        }
        else
        {
           print "Error in interface argument processing\n";
           next;
        }
      }
      elsif ($interface eq 'GLX')
      {
        if (!$found_libs->{GL} && !$found_libs->{MESA} && !$found_libs->{GLX})
        {
          print "GLX interface requires GLX/X11 but the libraries were not found\n";
          next;
        }
      }
      elsif (!$found_libs->{$interface})
      {
        print "$interface interface not supported\n";
        next;
      }

      push(@interface_opts,$interface);
    }
  }

  my $interfaces = scalar(@interface_opts);
  if (!$interfaces)
  {
    die "ERROR: no supported interfaces found.\n";
  }
  elsif ($interfaces > 1)
  {
    die "ERROR: multiple opengl interfaces requested: @interface_opts.\n";
  }

  ($interface_lib) = @interface_opts;
  print "User set interface to $interface_lib\n" if ($verbose && !$fallback);

  # Strip out interface args
  @ARGV = grep { !m/^interface=/i } @ARGV;
}
# Otherwise use available defaults
elsif ($IS_CYGWIN)
{
  if ($found_libs->{FREEGLUT})
  {
    $interface_lib = 'FREEGLUT'; # CYGWIN will use X11 interface by default
  }
  elsif($found_libs->{GLUT})
  {
    $interface_lib = 'GLUT';
  }
  elsif($found_libs->{GLUT32} || $found_libs->{FREEGLUT32})
  {
    $interface_lib = 'W32API';
  }
  else
  {
    die "No suitable OpenGL+GLUT interface found for CYGWIN\n";
  }
}
elsif ($^O eq 'darwin' && $found_libs->{GLUT} && !$found_libs->{FREEGLUT})
{
  $interface_lib = 'AGL';
}
elsif ($found_libs->{FREEGLUT} || $found_libs->{FREEGLUT32})
{
  $interface_lib = 'FREEGLUT';
}
elsif ($found_libs->{GLUT} || $found_libs->{GLUT32})
{
  $interface_lib = 'GLUT';
}
else
{
  die "FreeGLUT or GLUT libraries were not found, won't build OpenGL::GLUT module.";
}

print "\nUsing interface: $interface_lib\n\n";

# Marshall compiler defines
our $DEFS = $DIST_DEFS;
if ($IS_STRAWBERRY)
{
  delete($found_libs->{'GLX'});
  delete($found_libs->{'MESA'});
  $found_libs->{'GLU'} = $found_libs->{'GLU32'};
  $found_libs->{'GL'} = $found_libs->{'OPENGL32'};
  $DEFS .= " -DIS_STRAWBERRY";
}
elsif (($^O eq 'MSWin32') || $IS_W32API || $IS_MINGW)
{
  delete($found_libs->{'GLX'});
  delete($found_libs->{'MESA'});
  $found_libs->{'FREEGLUT'} = $found_libs->{'FREEGLUT32'};
  $found_libs->{'GLUT'} = $found_libs->{'GLUT32'};
  $found_libs->{'GLU'} = $found_libs->{'GLU32'};
  $found_libs->{'GL'} = $found_libs->{'OPENGL32'};
}
elsif($IS_CYGWIN)
{
  delete($found_libs->{'FREEGLUT32'});
  delete($found_libs->{'GLUT32'});
  delete($found_libs->{'GLU32'});
  delete($found_libs->{'OPENGL32'});
}

if (0) { # May be not necessary now, see if removing makes a difference
   if (!$found_libs->{'GL'})
   {
      if ($found_libs->{'GLX'})
      {
         $found_libs->{'GL'} = $found_libs->{'GLX'};
      }
      elsif ($found_libs->{'MESA'})
      {
         $found_libs->{'GL'} = $found_libs->{'MESA'};
      }
   }
}

print "resulting libs:\n" if ($verbose);
foreach my $key (sort keys %$found_libs)
{
  next if (!$found_libs->{$key});
  $DEFS .= " -DHAVE_$key";
  print "    $key = '$found_libs->{$key}'\n" if ($verbose);
}

# Configure MakeMaker
my($LIBS,$OPTS,$CLEAN,$LDFROM);
my $EXES = [];
my $DYNS = {};
if ($IS_W32API || (($^O eq 'MSWin32') && !$IS_CYGWIN))		# Win32
{
  my $glut_lib = '-lopengl32 -lglu32 ';
  if ($interface_lib eq 'GLUT')
  {
    $glut_lib .= '-lglut32';
  }
  elsif ($interface_lib eq 'FREEGLUT' and $IS_STRAWBERRY)
  {
    $glut_lib .= '-lglut';
  }
  else
  {
    $glut_lib .= '-LFreeGLUT -lfreeglut';
  }

  if ($IS_MINGW)	# MINGW
  {
    $LDFROM = $glut_lib;
  }
  elsif ($IS_W32API)	# CYGWIN W32API
  {
     my $glut = ($found_libs->{FREEGLUT32}) ? $found_libs->{FREEGLUT32} : $found_libs->{GLUT32};

    $LIBS = "-L/usr/lib/w32api $glut_lib";
    $LDFROM = $glut_lib;
    ### $INCS = '-I/usr/include/w32api';
    $INCS = '-I/usr/include/opengl';
    $DEFS .= " -DHAVE_W32API";
    $DYNS = { OTHERLDFLAGS => '-Wl,--exclude-symbols,'."\x7F".$glut.'_NULL_THUNK_DATA' };
  }
  else			# Windows VC6
  {
    $LIBS = $glut_lib;
    $OPTS = "/ogity /GDs";
  }

  # Using a dll as EXES is incorrect for EU::MM, since the EXES here mean
  # perl scripts and not windows binaries or DLLs.  This puts the DLL in
  # blib/bin from whence it should be installed correctly.  It is not
  # clear that this step is even needed since the freeglut.dll is installed
  # by this Makefile.PL if no FreeGLUT is found.
  #
  ## $EXES = ['FreeGLUT/freeglut.dll'];
  {
     system $^X , qw[-MExtUtils::Command -e mkpath --], qw[blib/arch/auto/OpenGL/GLUT/];
     system $^X , qw[-MExtUtils::Command -e cp --], qw[FreeGLUT/freeglut.dll blib/arch/auto/OpenGL/GLUT/freeglut.dll];
     my @other_installs = grep { -e "$_\\freeglut.dll" } split /;/, $ENV{PATH};
     if(@other_installs) {
      print "\n" ;
      print "XXX Other freeglut.dll installed in $_\n" for @other_installs;
      print "Please verify whether the other found dll(s) are from older OpenGL.pm installs, and delete them if so!\n\n\n";
      sleep 2;
     }
  }

}
elsif ($interface_lib eq 'AGL')					# Mac OS X
{
  $INCS = ""; # no include flags required: Apple gcc will automatically pick up the system frameworks
  $DEFS .= " -DHAVE_AGL_GLUT -Wno-deprecated-declarations ";  # So we know we have glutWMCloseFunc() and glutCheckLoop()
  $DYNS = { OTHERLDFLAGS => "-framework OpenGL -framework GLUT" };
}
else # Everyone else
{
  my @includes = qw
  {
    -I/usr/include
    -I/usr/include
    -I/usr/X11R6/include
    -I/opt/X11/include
    -I/usr/local/include
    -I/usr/openwin/include
    -I/opt/csw/include
    -I/usr/local/freeglut/include
  };
  $INCS = "@includes";


  # Test for obfuscated GLX
  # quite often GLX is in -lGL...  Test for GL/glx.h instead...
  my $out = cfile_text('GL/glx.h');

  # The cpp would not let this macro through. Check for something else
  # that still exists after the cpp pass. a typedef, or type would work
  my $has_glx = ($out =~ m|GLXContext|);

  if ($has_glx)
  {
    #delete($found_libs->{GLX});
    $DEFS .= " -DHAVE_GLX";
  }
  elsif (!$found_libs->{GLX} && $verbose)
  {
    print "GLX not found (neither library, nor headers).";
  }

  # Test for obfuscated Freeglut
  # quite often Freeglut is in -lglut...  Test for GL/freeglut.h instead...
  $out = cfile_text('GL/freeglut.h');

  # The cpp would not let this macro through. Check for something else
  # that still exists after the cpp pass. a typedef, or type would work
  my $has_freeglut = ($out =~ m|glutMainLoopEvent|);

  if ($has_freeglut)
  {
    #delete($found_libs->{GLX});
    $DEFS .= " -DHAVE_FREEGLUT -DHAVE_FREEGLUT_H";
    $found_libs->{FREEGLUT}="glut";
  }

  # Marshall libs
  my $libs = ' -l'.join(' -l',sort values(%$found_libs));
  my @more_libs = qw
  {
    -lXext
    -lXmu
    -lXi
    -lICE
    -lX11
    -lstdc++
    -lm
  };
  #-lXIE
  $LIBS = "@libdirs $libs @more_libs";
  $DEFS .= " -DGL_GLEXT_LEGACY";


  # Handle obfuscated gcc
  my $no_lgcc = (grep /^NO_LGCC$/, @ARGV);
  @ARGV = grep !/^NO_LGCC$/, @ARGV;

  if (!$no_lgcc)
  {
    # This may be a gcc compiler in disguise.
    # Should check for gccversion as well.
    if ($Config{cc} ne 'gcc' && !$Config{gccversion})
    {
      my $gcclibdir;
      my $gccout = `gcc -v 2>&1`;
      if ($gccout =~ /specs from (.*)/)	# gcc present
      {
        ($gcclibdir = $1) =~ s,\bspecs\s*$,,;
        $LIBS .= " -L$gcclibdir -lgcc";

        print STDERR qq
        {
#
### Non-gcc compiler, and gcc is present.
### Adding -lgcc as a dependency: your OpenGL libraries may be gcc-compiled.
### Use NO_LGCC command-line option to disable this.
#
        };
      }
    }
  }
}

# Check for gcc version 3.2.3 and turn off OPTIMIZE to work
# around compiler bug reported via cpan testers reports
if ( defined( $Config{gccversion} )  and $Config{gccversion} =~ /^3\.2\.3 / ) {
   $OPTS = '-O0';       # turn off optimization for gcc 3.2.3
}

clean_incs( $INCS );

clean_libs( $LIBS );

# This is the final build configuration
my $build_config =
{
  'NAME'	=> 'OpenGL::GLUT',
  'VERSION_FROM'=> 'lib/OpenGL/GLUT.pm',
  'PREREQ_PM' => { 'Test::More' => 0 },
  'AUTHOR'	=> "Chris Marshall ".'<chm at cpan dot org>',
  'OBJECT' 	=> '$(BASEEXT)$(OBJ_EXT) gl_util$(OBJ_EXT) pogl_const$(OBJ_EXT) pogl_gl_top$(OBJ_EXT)',
  'XSPROTOARG'	=> '-noprototypes',
  'DEFINE'	=> $DEFS,
  'INC'		=> $INCS,
  'LIBS' 	=> $LIBS,
  'dynamic_lib'	=> $DYNS,
  'LDFROM'      => '$(OBJECT) '.(defined($LDFROM)?$LDFROM:''),
  'META_MERGE' => {
     abstract  => 'Perl bindings to the GLUT/FreeGLUT toolkit',
     resources => {
        homepage => 'http://sourceforge.net/projects/pogl/',
        bugtracker  => 'http://sourceforge.net/tracker/?group_id=562483&atid=2281758',
        repository  => 'git://pogl.git.sourceforge.net/gitroot/pogl/pogl',
     },
  },
  'EXE_FILES'	=> $EXES,
  'OPTIMIZE'	=> $OPTS,
  'clean'       =>
  {
    FILES =>
      "utils/glversion.txt ".
      "utils/glversion$Config{exe_ext} ".
      "utils/glversion$Config{obj_ext}"
  }
};

print "\nMakeMaker configuration:\n" if $verbose;

WriteMakefile( %$build_config );       		# Generate the Makefile

if ($found_libs->{GLX} && $ENV{TERM} ne 'xterm')
{
  print "\nThis configuration should be built under an X11 shell\n\n";
}

1; # to signal that the eval didn't bail out early
};

die "$@\nOS unsupported\n" if !$prepare_success;

exit 0;



# test header files for extensions
sub cfile_text
{
  my($filename) = @_;

  # Use $Config{cpprun}, instead of $Config{cpp}. cpp is simply set to
  # 'cpp' after Configure has run, which is not useful, since it lives
  # in /lib/ on many systems, which is normally not on the path.  This
  # is documented, but silly behaviour.  $Config{cpprun} is what is
  # documented to be set to a cpp that will take stuff on stdin

  my $cmd = "echo '\#include \"$filename\"' | ".
    "$Config{cpprun} $INCS $Config{cppflags} $Config{cppminus} 2>&1";

  return `$cmd`;
}


# Find OpenGL-related Libs
sub get_libs
{
  my @glx_libs = @_;
  my $found = {};
  my $libs;

  # Mac OS X
  if ($^O eq 'darwin' && -d '/System/Library/Frameworks/OpenGL.framework')
  {
    $found->{GL} = 'OpenGL.framework';
    $found->{GLU} = 'AGL.framework';
    if (-e '/opt/X11/lib/libglut.3.dylib')
    {
      $found->{FREEGLUT} = 'glut';
    }
    else
    {
      $found->{GLUT} = 'GLUT.framework';
    }
    return $found;
  }

  # Win32
  if ($IS_STRAWBERRY)
  {
     # libs for strawberry perl go here
     $found->{FREEGLUT} = 'glut';
     $found->{OPENGL32} = 'opengl32';
     $found->{GLU32} = 'glu32';
  }
  elsif (($^O eq 'MSWin32') || $IS_W32API)
  {
    my $paths = $ENV{PATH};
    $paths =~ s|\\|/|g;
    my $sep = $IS_W32API ? ':' : ';';
    my @paths = split($sep.'\s*',$paths);

    my $sysroot = $ENV{'SYSTEMROOT'};
    @paths = ("$sysroot/system32",@paths) if ($sysroot);

    $libs = {OPENGL32=>'opengl32.dll',GLU32=>'glu32.dll',GLUT32=>'glut32.dll',FREEGLUT32=>'freeglut.dll'};
    foreach my $key (sort keys %$libs)
    {
      foreach my $path (@paths)
      {
        $path =~ s|/$||;
        my $lib = $libs->{$key};
        next if (!-e "$path/$lib");
        $lib =~ s/\.dll$//i;
        if ( $lib eq "freeglut" ) {
          my @p = split m@[/\\]@, $Config{installsitebin};
          next if $path eq join "/", @p or $path eq join "\\", @p;
        }
        # print "  $key: $lib\n";
        $found->{$key} = $lib;
        last;
      }
    }

    # Install FreeGLUT if not found
    if (!$found->{FREEGLUT32} and !$IS_STRAWBERRY)
    {
      my $dll_dir = "utils";

      my $exec;
      if ($IS_W32API)
      {
        $dll_dir = '/usr/local/bin' if ($dll_dir eq '/usr/bin');
        $exec = "cp FreeGLUT/freeglut.dll $dll_dir";
      }
      else
      {
        $exec = "copy FreeGLUT\\freeglut.dll $dll_dir";
      }
      `$exec`;

      if (! -x "$dll_dir/freeglut.dll")
      {
         my $mode = (stat("$dll_dir/freeglut.dll"))[2];
         my $perm = $mode & 07777;
         print "freeglut.dll not executable (perms=%4o), changing permissions...\n";
         chmod $perm|0755, "$dll_dir/freeglut.dll" or warn "Error changing freeglut.dll perms: $!";
      }


      if (-e "$dll_dir/freeglut.dll")
      {
        print "Installed freeglut.dll at $dll_dir\n";
        $found->{FREEGLUT32} = 'freeglut'
      }
      else
      {
        print "Unable to install freeglut.dll to $dll_dir\n";
        print "Try manually copying FreeGLUT/freeglut.dll to a folder in your PATH.\n";
      }
    }

    return $found if (!$IS_W32API);
  }


  # Everyone else
  ($libs) = do {
    local $SIG{__WARN__} = sub  {
      my ( $warning ) = @_;
      return if $warning =~ /Warning \(mostly harmless\): No library found for/;
      warn $warning;
    };
    ExtUtils::Liblist->ext(join(' ',@glx_libs),0);
  };

  foreach my $lib (split(' ',$libs))
  {
    next if ($lib =~ m|^-L|);
    $lib =~ s/^-l//;
    #print "  $lib\n";

    if ($lib =~ m|([\w]*freeglut[\w]*)|i)
    {
      $found->{FREEGLUT} = $1;
    }
    elsif ($lib =~ m|([\w]*glut[\w]*)$|i)
    {
      $found->{GLUT} = $1;
    }
    elsif ($lib =~ m|([\w]*glu[\w]*)$|i)
    {
      $found->{GLU} = $1;
    }
    elsif ($lib =~ m|([\w-]*glx)$|i)
    {
      $found->{GLX} = $1;
    }
    elsif ($lib =~ m|([\w]*gl)$|i)
    {
      $found->{GL} = $1;
    }

    if ($lib =~ m|([\w]*mesa(gl)?.*)|i)
    {
      $found->{MESA} = $1;
    }
  }

  return $found;
}


# Test for available OpenGL Extensions
sub get_extensions
{
  my($found,$no_excl) = @_;
  print "Testing for OpenGL Extensions\n" if ($verbose);

  # clean up previous output files
  my $exc_file = 'gl_exclude.h';
  unlink($exc_file) if (-e $exc_file);
  my $glv_file = 'utils/glversion.txt';
  unlink($glv_file) if (-e $glv_file);

  # Only run the rest if GLUT is installed
  print "Testing GLUT version\n" if ($verbose);
  my($lib,$def);
  if ($found->{FREEGLUT32} || $found->{FREEGLUT})
  {
    $lib = $found->{FREEGLUT32} || $found->{FREEGLUT};
    $def = "HAVE_FREEGLUT";
  }
  elsif ($found->{GLUT32} || $found->{GLUT})
  {
    $lib = $found->{GLUT32} || $found->{GLUT};
    $def = "HAVE_GLUT";
  }
  elsif ($verbose)
  {
    print "GLUT not found\n";
  }

  # Platform-specific makefiles for glversion
  my $make_ver;
  if ($IS_STRAWBERRY)
  {
    $make_ver = "&strawberry.bat";
    print "strawberry glversion: '$make_ver'\n" if $verbose>1;
  }
  elsif ($IS_MINGW)
  {
    $make_ver = "&mingw.bat";
    print "mingw glversion: '$make_ver'\n" if $verbose>1;
  }
  elsif ($IS_W32API)
  {
    $make_ver = ";make -f Makefile.cygwin " .  (length($lib) ? "GLUT_LIB=$lib " : "") . (length($def) ? "GLUT_DEF=$def " : "");
    print "cygwin glversion: '$make_ver'\n" if $verbose>1;
  }
  elsif ($^O eq 'MSWin32')
  {
    $make_ver = '&nmake -f makefile.mak ' . (length($def) ? "GLUT_DEF=$def " : "");
    print "MSWin32 glversion: '$make_ver'\n" if $verbose>1;
  }
  elsif ($^O eq 'darwin')
  {
    $make_ver = ";make -f Makefile.macosx " .  (length($lib) ? "GLUT_LIB=$lib " : "") . (length($def) ? "GLUT_DEF=$def " : "");
    print "MacOSX glversion: '$make_ver'\n" if $verbose>1;
  }
  else
  {
    if ($ENV{TERM} ne 'xterm')
    {
      print "\nIn order to test your GPU's capabilities, run this make under an X11 shell\n\n";
    }

    $make_ver = ";make -f Makefile " .  (length($lib) ? "GLUT_LIB=$lib " : "") . (length($def) ? "GLUT_DEF=$def " : "");
    print "glversion: '$make_ver'\n" if $verbose>1;
  }
  my $exec = 'cd utils'."$make_ver clean".$make_ver;
  print "glversion: $exec\n" if ($verbose);
  my $stat = `$exec`;
  print "\n$stat\n\n" if ($verbose);
  unlink "utils/freeglut.dll" or die "could not remove temporary freeglut: $!" if -f "utils/freeglut.dll";

  # Parse glversion.txt file
  open GLDATA, $glv_file or die "get_extensions: could not open $glv_file: $!\n";
  my $gldata = {};
  my @gldata = <GLDATA>;
  close(GLDATA);

  foreach my $line (@gldata)
  {
    $line =~ s|[\r\n]+||;
    my($key,$val) = split('=',$line);
    $gldata->{$key} = $val;
  }
  die "get_extensions: no extensions found in $glv_file\n" if !keys %$gldata;

  print "This looks like OpenGL Version: $gldata->{VERSION}\n";

  # Parse glext_procs.h file
  open GLEXT, "glext_procs.h" or die "get_extensions: could not open glext_procs.h: $!\n";
  my @lines = <GLEXT>;
  close(GLEXT);

  my $no_ext = {};
  foreach my $line (@lines)
  {
    next if ($line !~ m|\#ifndef NO_([^\s]+)|);
    my $ext = $1;
    next if ($ext =~ m|^GL_VERSION_|);
    $no_ext->{$ext}++;
  }


  # Create gl_exclude.h
  die "Unable to write to $exc_file\n" if (!open(GLEXC,">$exc_file"));
  print GLEXC "// OpenGL Extension Exclusions - may be modified before building.\n";
  print GLEXC "//\n";
  print GLEXC "// Generated for ".$gldata->{VENDOR}.", ".$gldata->{RENDERER}."\n";
  print GLEXC "// OpenGL v".$gldata->{VERSION}.", using ";

  # Fix GLUT flags based on results
  if ($gldata->{FREEGLUT})
  {
    print 'Found FreeGLUT v'.$gldata->{FREEGLUT}."\n";
    print GLEXC 'FreeGLUT v'.$gldata->{FREEGLUT}."\n";

    if (!$found->{FREEGLUT} && !$found->{FREEGLUT32})
    {
      $found->{FREEGLUT} = $lib;
    }
  }
  elsif ($gldata->{GLUT})
  {
    print "Found GLUT - Version: $gldata->{GLUT}\n";
  }
  else
  {
    print "Found no GLUT\n"
  }

  my $GL_VERSION;
  my($GL_VERSION_MAJOR, $GL_VERSION_MINOR);
  if ($gldata->{VERSION} =~ m|^(\d\.\d+)|)
  {
    $GL_VERSION = $1;
    ($GL_VERSION_MAJOR,$GL_VERSION_MINOR) = split('.', $GL_VERSION);
  }

  # Make an empty exclusion file if a Windows distribution build
  if ($no_excl)
  {
    print "OpenGL Extension exclusions disabled\n";
    print GLEXC "//\n";
    print GLEXC "// Exclusions omitted for distribution build.\n";
  }
  else
  {
    print GLEXC "\n";
    if ($GL_VERSION)
    {
      print GLEXC "#define NO_GL_VERSION_4_5\n" if ($GL_VERSION < 4.5);
      print GLEXC "#define NO_GL_VERSION_4_4\n" if ($GL_VERSION < 4.4);
      print GLEXC "#define NO_GL_VERSION_4_3\n" if ($GL_VERSION < 4.3);
      print GLEXC "#define NO_GL_VERSION_4_2\n" if ($GL_VERSION < 4.2);
      print GLEXC "#define NO_GL_VERSION_4_1\n" if ($GL_VERSION < 4.1);
      print GLEXC "#define NO_GL_VERSION_4_0\n" if ($GL_VERSION < 4.0);
      print GLEXC "#define NO_GL_VERSION_3_3\n" if ($GL_VERSION < 3.3);
      print GLEXC "#define NO_GL_VERSION_3_2\n" if ($GL_VERSION < 3.2);
      print GLEXC "#define NO_GL_VERSION_3_1\n" if ($GL_VERSION < 3.1);
      print GLEXC "#define NO_GL_VERSION_3_0\n" if ($GL_VERSION < 3.0);
      print GLEXC "#define NO_GL_VERSION_2_1\n" if ($GL_VERSION < 2.1);
      print GLEXC "#define NO_GL_VERSION_2_0\n" if ($GL_VERSION < 2.0);
      print GLEXC "#define NO_GL_VERSION_1_5\n" if ($GL_VERSION < 1.5);
      print GLEXC "#define NO_GL_VERSION_1_4\n" if ($GL_VERSION < 1.4);
      print GLEXC "#define NO_GL_VERSION_1_3\n" if ($GL_VERSION < 1.3);
      print GLEXC "#define NO_GL_VERSION_1_2\n" if ($GL_VERSION < 1.2);
      print GLEXC "#define NO_GL_VERSION_1_1\n" if ($GL_VERSION < 1.1);
    }

    foreach my $ext (split(' ',$gldata->{EXTENSIONS}))
    {
      next if (!$no_ext->{$ext});
      $no_ext->{$ext} = 0;
    }

    foreach my $ext (sort keys(%$no_ext))
    {
      next if (!$no_ext->{$ext});
      print GLEXC "#define NO_$ext\n";
    }
  }

  close(GLEXC);


  # return Distributable Defs
  print "Have Version Data\n" if ($verbose);
  my $defines = '-DHAVE_VER';
  $defines .= " -DGL_VERSION_USED=$GL_VERSION" if ($GL_VERSION);
  return $defines;
}

# Takes as input a INCS string ready for MakeMaker and cleans out
# non-existant directories produce a minimal configuration value
sub clean_incs {
   my $inincs = $_[0];
   return unless defined $inincs;
   print "clean_incs: got input INCS='$inincs'\n" if $verbose>1;

   my @inincs = split / /, $inincs;

   # clean out -I args with non-existent directories
   print "clean_incs: removing bad directories\n" if $verbose>1;
   my @outincs = grep { my $tmp = $_; $tmp =~ s/^-I// and ( -d $tmp or -l $tmp) } @inincs;
   my $outincs = join ' ', @outincs;

   print "clean_incs: returning INCS='$outincs'\n" if $verbose>1;
   $_[0] = $outincs;
}

# Takes as input a LIBS string ready for MakeMaker and cleans out
# non-existant directories and libraries to produce a better,
# minimal configuration value
sub clean_libs {
   my $inlibs = $_[0];
   return unless defined $inlibs;
   print "clean_libs: got input LIBS='$inlibs'\n" if $verbose>1;

   my @inlibs = split ' ', $inlibs;

   # clean out -L args with non-existent directories
   print "clean_libs: removing bad directories\n" if $verbose>1;
   my @outlibs = grep { my $tmp = $_; /^-l/ or $tmp =~ s/^-L// and ( -d $tmp or -l $tmp) } @inlibs;


   my $outlibs = join ' ', @outlibs;

   print "clean_libs: returning LIBS='$outlibs'\n" if $verbose>1;
   $_[0] = $outlibs;
}
