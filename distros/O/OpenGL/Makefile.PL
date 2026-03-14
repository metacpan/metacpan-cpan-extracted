use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;
use Config;
use File::Spec::Functions;

# Supported windowing interfaces
our $is_valid_interface =
{
  'AGL'       => 'Default GLUT framework on Mac OS X',
  'FREEGLUT'  => 'FreeGLUT, preferred over GLUT',
  'GLUT'      => 'GLUT; often really FreeGLUT on Linux',
  'GLX'       => 'Default GLX+X11 on Linux; use XQuartz on Mac OS X',
  'W32API'    => 'Uses WGL+FreeGLUT on CYGWIN, instead of GLX+FreeGLUT',
  'WGL'       => 'Same as W32API',
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

our $verbose = grep m/^verbose/i, @ARGV; # Get debugging flags
print "\$verbose set to $verbose" . ($verbose ? "" : " - enable by running as `perl Makefile.PL verbose`");
print "\n\n";

our $IS_MINGW = $^O eq 'MSWin32' && $Config{cc} =~ /\bgcc/i;
print "Build platform \$IS_MINGW==1" if $IS_MINGW and $verbose;
our $IS_STRAWBERRY = $IS_MINGW && $Config{cf_by} =~ m/strawberry-perl/i;
print "Build platform \$IS_STRAWBERRY==$IS_STRAWBERRY\n" if $IS_STRAWBERRY and $verbose;
our $IS_CYGWIN = $^O eq 'cygwin';
print "Build platform \$IS_CYGWIN==$IS_CYGWIN\n" if $IS_CYGWIN and $verbose;
our $IS_W32API = ($IS_CYGWIN && grep { m/^interface=(W32API|WGL)/i } @ARGV );
print "Build platform \$IS_W32API==$IS_W32API\n" if $IS_W32API and $verbose;

our $INCS;
our $NO_LGCC = grep /^NO_LGCC$/, @ARGV;

my $prepare_success = eval {
# Look for available libs
our @libdirs = map "-L$_", grep -d, qw(
  /usr/X11R6/lib
  /opt/X11/lib
  /usr/local/lib
  /usr/openwin/lib
  /opt/csw/lib
  /opt/local/lib
  /usr/local/freeglut/lib
  /usr/lib
  /usr/lib/xorg/modules
  /usr/X11R6/lib/modules
  /usr/lib/xorg/modules/extensions
  /usr/X11R6/lib/modules/extensions
);

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

our $found_libs = get_found_libs(\@libdirs,@check_libs);
die "No OpenGL related libs found\n" if !$found_libs;
if ($verbose) {
  print "found libs:\n";
  print "    $_ = '$found_libs->{$_}'\n" for sort keys %$found_libs;
}

# Get user-specified interface
my $interface_lib = get_interface_lib(\@ARGV, $found_libs, $is_valid_interface);
print "\nUsing interface: $interface_lib\n\n";
delete @$found_libs{grep /^GLUT/, keys %$found_libs} if $interface_lib eq 'FREEGLUT';
delete @$found_libs{grep /^FREEGLUT/, keys %$found_libs} if $interface_lib =~ /^(GLUT|AGL)$/;

$INCS = get_incs($interface_lib);

our $DEFS = get_defines($found_libs, $interface_lib, $INCS);

# Configure MakeMaker
my $OPTS = $^O eq 'MSWin32' && !$IS_MINGW ? "/ogity /GDs" : undef;
my $DYNS = get_dyns($found_libs);
my $LIBS = get_libs($found_libs, $interface_lib, \@libdirs);

my $gldata = get_gldata($found_libs, $INCS, $DEFS, $LIBS);
generate_excl($gldata);

# This is the final build configuration
my $build_config =
{
  DEFINE => $DEFS,
  INC => $INCS,
  LIBS => $LIBS,
  !defined($DYNS) ? () : (dynamic_lib => $DYNS),
  !defined($OPTS) ? () : (OPTIMIZE => $OPTS),
};

WriteConfigPM( $build_config ); # generate final Config.pm
WriteMakefile(
  NAME	=> 'OpenGL',
  VERSION_FROM=> 'lib/OpenGL.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.12', # XSBUILD
  },
  PREREQ_PM => {
    'OpenGL::Modern' => '0.0403', # registry more accurate aliases
  },
  TEST_REQUIRES => { 'Test::More' => '0.88' },
  AUTHOR	=> "Chris Marshall ".'<chm at cpan dot org>',
  MIN_PERL_VERSION => '5.016', # like OGLM, for visibility
  XSMULTI => 1,
  XSBUILD => {
    xs => {
      map +($_ => {OBJECT => "$_\$(OBJ_EXT) gl_util\$(OBJ_EXT)"}),
        map "lib/OpenGL/$_", qw(V1 V2 Array Matrix Const GLX GLU GLUT),
    },
  },
  XSPROTOARG	=> '-noprototypes',
  TYPEMAPS => [qw(lib/OpenGL/Install/typemap)],
  META_MERGE => {
     "meta-spec" => { version => 2 },
     dynamic_config => 0,
     abstract  => 'Perl bindings to the OpenGL API, GLU, and GLUT/FreeGLUT',
     resources => {
        homepage => 'http://sourceforge.net/projects/pogl/',
        bugtracker  => {web=>'https://github.com/Perl-GPU/pogl/issues'},
        repository  => {
           url => 'git://github.com/Perl-GPU/pogl.git',
           type => 'git',
           web => 'https://github.com/Perl-GPU/pogl',
        },
        x_IRC => 'irc://irc.perl.org/#pogl',
     },
  },
  clean => {
    FILES => join(' ',
      qw(lib/OpenGL/Config.pm gl_exclude.h utils/glversion.txt auto-xs.inc),
      "utils/glversion$Config{exe_ext}",
      "utils/glversion$Config{obj_ext}"
    ),
  },
  depend => {
    'lib/OpenGL/V2$(OBJ_EXT)' => 'auto-xs.inc',
  },
  %$build_config,
  INC => $INCS . ' -I'.curdir(),
);       		# Generate the Makefile

if ($found_libs->{GLX} && $ENV{TERM} !~ /^xterm/) {
  print "\nThis configuration should be built under an X11 shell\n\n";
}

1; # to signal that the eval didn't bail out early
};

die "$@\nOS unsupported\n" if !$prepare_success;

exit 0;

{
package MY; # so that "SUPER" works right
sub postamble {
  <<EOF;
auto-xs.inc : utils/generate-XS.pl lib/OpenGL/Misc.pm
\t\$(PERLRUN) -Ilib utils/generate-XS.pl
EOF
}
sub init_PM {
  my ($eumm) = @_;
  $eumm->SUPER::init_PM;
  my $pm = $eumm->{PM};
  delete @$pm{grep /(?:\.(?:c|xs|bs)|\Q$::Config{obj_ext}\E)$/, keys %$pm};
  delete @$pm{grep /\.pl$/, keys %$pm};
}
}

# test header files for extensions
sub cfile_text {
  my ($filename, $incs) = @_;
  # Use $Config{cpprun}, instead of $Config{cpp}. cpp is simply set to
  # 'cpp' after Configure has run, which is not useful, since it lives
  # in /lib/ on many systems, which is normally not on the path.  This
  # is documented, but silly behaviour.  $Config{cpprun} is what is
  # documented to be set to a cpp that will take stuff on stdin
  my $cmd = "echo '\#include \"$filename\"' | ".
    "$Config{cpprun} $incs $Config{cppflags} $Config{cppminus} 2>&1";
  return `$cmd`;
}

sub get_dyns {
  my ($found_libs) = @_;
  return if !$IS_W32API;
  my $glut = $found_libs->{FREEGLUT32} || $found_libs->{GLUT32};
  $glut =~ s/^-l//;
  { OTHERLDFLAGS => '-Wl,--exclude-symbols,'."\x7F".$glut.'_NULL_THUNK_DATA' };
}

sub get_libs {
  my ($found_libs, $interface_lib, $ldirs) = @_;
  return "-framework OpenGL -framework GLUT -lm" if $interface_lib eq 'AGL';
  return +($IS_W32API ? "-L/usr/lib/w32api " : '') .
    '-lopengl32 -lglu32 ' . (
      $interface_lib eq 'GLUT' ? '-lglut32' :
      $interface_lib eq 'FREEGLUT' && $IS_STRAWBERRY ? '-lglut' :
      '-LFreeGLUT -lfreeglut'
    )
      if $IS_W32API || $^O eq 'MSWin32';
  my $libs = join '', map " $_", grep $_, sort(values %$found_libs), '-lm';
  $libs = "@$ldirs $libs";
  return $libs if $NO_LGCC || $Config{cc} eq 'gcc' || $Config{gccversion};
  # Handle obfuscated gcc
  # This may be a gcc compiler in disguise.
  my $gccout = `gcc -v 2>&1`;
  return $libs if $gccout !~ /specs from (.*)/;
  (my $gcclibdir = $1) =~ s,\bspecs\s*$,,;
  print STDERR <<'EOF';
#
### Non-gcc compiler, and gcc is present.
### Adding -lgcc as a dependency: your OpenGL libraries may be gcc-compiled.
### Use NO_LGCC command-line option to disable this.
#
EOF
  $libs . " -L$gcclibdir -lgcc";
}

# Find OpenGL-related Libs
sub get_found_libs {
  my ($ldirs, @glx_libs) = @_;
  my $found = {};
  my $libs;
  # Mac OS X
  if ($^O eq 'darwin' && -d '/System/Library/Frameworks/OpenGL.framework') {
    $found->{GL} = '-framework OpenGL';
    $found->{GLU} = '';
    $found->{GLUT} = '-framework GLUT';
    for (@$ldirs) {
      (my $dir = $_) =~ s/^-L//;
      next if !-e "$dir/libglut.3.dylib";
      $found->{FREEGLUT} = '-lglut';
      last;
    }
    return $found;
  }
  # Win32
  if ($IS_STRAWBERRY) {
     # libs for strawberry perl go here
     $found->{FREEGLUT} = '-lglut';
     $found->{GL} = $found->{OPENGL32} = '-lopengl32';
     $found->{GLU} = $found->{GLU32} = '-lglu32';
  } elsif (($^O eq 'MSWin32') || $IS_W32API) {
    my $paths = $ENV{PATH};
    $paths =~ s|\\|/|g;
    my $sep = $IS_W32API ? ':' : ';';
    my @paths = split($sep.'\s*',$paths);
    unshift @paths, "$ENV{SYSTEMROOT}/system32" if $ENV{SYSTEMROOT};
    $libs = {OPENGL32=>'opengl32.dll',GLU32=>'glu32.dll',GLUT32=>'glut32.dll',FREEGLUT32=>'freeglut.dll'};
    foreach my $key (sort keys %$libs) {
      foreach my $path (@paths) {
        $path =~ s|/$||;
        my $lib = $libs->{$key};
        next if (!-e "$path/$lib");
        $lib =~ s/\.dll$//i;
        if ( $lib eq "freeglut" ) {
          my @p = split m@[/\\]@, $Config{installsitebin};
          next if $path eq join "/", @p or $path eq join "\\", @p;
        }
        # print "  $key: $lib\n";
        $found->{$key} = "-l$lib";
        last;
      }
    }
    # Install FreeGLUT if not found
    if (!$found->{FREEGLUT32} and !$IS_STRAWBERRY) {
      my $dll_dir = "utils";
      my $exec;
      if ($IS_W32API) {
        $dll_dir = '/usr/local/bin' if ($dll_dir eq '/usr/bin');
        $exec = "cp FreeGLUT/freeglut.dll $dll_dir";
      } else {
        $exec = "copy FreeGLUT\\freeglut.dll $dll_dir";
      }
      `$exec`;
      if (! -x "$dll_dir/freeglut.dll") {
         my $mode = (stat("$dll_dir/freeglut.dll"))[2];
         my $perm = $mode & 07777;
         print "freeglut.dll not executable (perms=%4o), changing permissions...\n";
         chmod $perm|0755, "$dll_dir/freeglut.dll" or warn "Error changing freeglut.dll perms: $!";
      }
      if (-e "$dll_dir/freeglut.dll") {
        print "Installed freeglut.dll at $dll_dir\n";
        $found->{FREEGLUT32} = '-lfreeglut'
      } else {
        print "Unable to install freeglut.dll to $dll_dir\n";
        print "Try manually copying FreeGLUT/freeglut.dll to a folder in your PATH.\n";
      }
    }
    delete @$found{qw(GLX MESA)};
    $found->{GL} = $found->{OPENGL32};
    $found->{GLU} = $found->{GLU32};
    $found->{FREEGLUT} = $found->{FREEGLUT32};
    $found->{GLUT} = $found->{GLUT32};
    return $found if (!$IS_W32API);
  }
  # Everyone else
  ($libs) = do {
    local $SIG{__WARN__} = sub  {
      my ( $warning ) = @_;
      return if $warning =~ /Warning \(mostly harmless\): No library found for/;
      warn $warning;
    };
    ExtUtils::Liblist->ext(join(' ', @$ldirs, @glx_libs),0);
  };
  foreach my $lib (split(' ',$libs)) {
    next if ($lib =~ m|^-L|);
    $lib =~ s/^-l//;
    #print "  $lib\n";
    if ($lib =~ m|([\w]*freeglut[\w]*)|i) {
      $found->{FREEGLUT} = "-l$1";
    } elsif ($lib =~ m|([\w]*glut[\w]*)$|i) {
      $found->{GLUT} = "-l$1";
    } elsif ($lib =~ m|([\w]*glu[\w]*)$|i) {
      $found->{GLU} = "-l$1";
    } elsif ($lib =~ m|([\w-]*glx)$|i) {
      $found->{GLX} = "-l$1";
    } elsif ($lib =~ m|([\w]*gl)$|i) {
      $found->{GL} = "-l$1";
    }
    if ($lib =~ m|([\w]*mesa(gl)?.*)|i) {
      $found->{MESA} = "-l$1";
    }
  }
  delete @$found{qw(FREEGLUT32 GLUT32 GLU32 OPENGL32)} if $IS_CYGWIN and !$IS_W32API;
  $found;
}

sub get_incs {
  my ($interface_lib) = @_;
  return '-I/usr/include/opengl' if $IS_W32API;	# CYGWIN W32API
  return '' if $^O eq 'MSWin32'; # Win32
  return "" if $interface_lib eq 'AGL'; # Mac OS X; no include flags required, Apple gcc will automatically pick up the system frameworks
  # Everyone else
  join ' ', map "-I$_", grep -d, qw{
    /usr/include
    /usr/include
    /usr/X11R6/include
    /opt/X11/include
    /usr/local/include
    /usr/openwin/include
    /opt/csw/include
    /opt/local/include
    /usr/local/freeglut/include
  };
}

sub get_interface_lib {
  my ($argv_ref, $found_libs, $is_valid_interface) = @_;
  my $interface_lib;
  if (my @if_args = map m/^interface=(\w+)/i ? $1 : (), @$argv_ref) {
    my @interface_opts = ();
    my $fallback = 0;
    foreach my $arg (@if_args) {
      my $interface = uc($arg);
      my $valid_type = $is_valid_interface->{$interface};
      if (!$valid_type) {
        Usage("Invalid interface: '$interface'");
        next;
      }
      # test if requested interfaces supported
      # !!! Should use lookup table
      if ($interface eq 'W32API' or $interface eq 'WGL') {
        if (!$found_libs->{FREEGLUT32} && !$found_libs->{GLUT32}) {
          print "W32API interface requires GLUT or FreeGLUT\n";
          next;
        }
        if (!$found_libs->{OPENGL32}) {
          print "W32API interface requires OpenGL32.dll\n";
          next;
        }
        if (!$found_libs->{GLU32}) {
          print "W32API interface requires GLU32.dll\n";
          next;
        }
      } elsif ($interface eq 'AGL') {
        if ($^O ne 'darwin' || !$found_libs->{GLUT}) {
          print "AGL interface requires GLUT.framework\n";
          next;
        }
      } elsif ($interface =~ m|GLUT|) {
        if ($interface eq 'FREEGLUT') {
          if (!$found_libs->{FREEGLUT} && !$found_libs->{FREEGLUT32}) {
            print "FREEGLUT interface requires FreeGLUT\n";
            if ($found_libs->{GLUT}) {
              print "Falling back to the GLUT interface\n";
              $interface = 'GLUT';
              $fallback++;
            } else {
              print "Try installing FREEGLUT first\n";
              next;
            }
          }
        } elsif ($interface eq 'GLUT') {
          if (!$found_libs->{GLUT} && $found_libs->{FREEGLUT}) {
            $found_libs->{GLUT} = $found_libs->{FREEGLUT};
          }
          if (!$found_libs->{GLUT32} && $found_libs->{FREEGLUT32}) {
            $found_libs->{GLUT32} = $found_libs->{FREEGLUT32};
          }
          if ($found_libs->{GLUT}) {
            delete($found_libs->{FREEGLUT});
          }
          if ($found_libs->{GLUT32}) {
            delete($found_libs->{FREEGLUT32});
          }
          if (!$found_libs->{GLUT} && !$found_libs->{GLUT32}) {
            print "GLUT interface requires GLUT or FreeGLUT but libs were not found\n";
            next;
          }
        } else {
          print "Error in interface argument processing\n";
          next;
        }
      } elsif ($interface eq 'GLX') {
        if (!$found_libs->{GL} && !$found_libs->{MESA} && !$found_libs->{GLX}) {
          print "GLX interface requires GLX/X11 but the libraries were not found\n";
          next;
        }
      } elsif (!$found_libs->{$interface}) {
        print "$interface interface not supported\n";
        next;
      }
      push(@interface_opts,$interface);
    }
    die "ERROR: no supported interfaces found.\n" if !@interface_opts;
    die "ERROR: multiple opengl interfaces requested: @interface_opts.\n"
      if @interface_opts > 1;
    ($interface_lib) = @interface_opts;
    print "User set interface to $interface_lib\n" if $verbose && !$fallback;
    return $interface_lib;
  }
  # Otherwise use available defaults
  if ($IS_CYGWIN) {
    return 'FREEGLUT' if $found_libs->{FREEGLUT}; # CYGWIN will use X11 interface by default
    return 'GLUT' if $found_libs->{GLUT};
    return 'W32API' if $found_libs->{GLUT32} || $found_libs->{FREEGLUT32};
    die "No suitable OpenGL+GLUT interface found for CYGWIN\n";
  }
  return 'AGL' if $^O eq 'darwin' && $found_libs->{GLUT} && !$found_libs->{FREEGLUT};
  return 'FREEGLUT' if $found_libs->{FREEGLUT} || $found_libs->{FREEGLUT32};
  return 'GLUT' if $found_libs->{GLUT} || $found_libs->{GLUT32};
  die "FreeGLUT or GLUT libraries were not found, won't build OpenGL module.";
}

# Test for available OpenGL Extensions
sub get_gldata {
  my ($found, $incs, $defs, $libs) = @_;
  print "Testing for OpenGL Extensions\n" if $verbose;
  # clean up previous output files
  my $glv_file = 'utils/glversion.txt';
  unlink($glv_file) if (-e $glv_file);
  # Only run the rest if GLUT is installed
  print "Testing GLUT version\n" if $verbose;
  my $lib = $found->{FREEGLUT32} || $found->{FREEGLUT} || $found->{GLUT32} || $found->{GLUT};
  print "GLUT not found\n" if $verbose and !$lib;
  my $def =
    ($found->{FREEGLUT32} || $found->{FREEGLUT}) ? "GLUT_DEF=HAVE_FREEGLUT " :
    ($found->{GLUT32} || $found->{GLUT}) ? "GLUT_DEF=HAVE_GLUT " :
    '';
  # Platform-specific makefiles for glversion
  my $make_ver;
  my $append = " LIB='$libs' INC='$incs' DEF='$defs'";
  if ($IS_STRAWBERRY) {
    $make_ver = "&strawberry.bat";
    print "strawberry glversion: '$make_ver'\n" if $verbose>1;
  } elsif ($IS_MINGW) {
    $make_ver = "&mingw.bat";
    print "mingw glversion: '$make_ver'\n" if $verbose>1;
  } elsif ($IS_W32API) {
    $make_ver = ";make -f Makefile.cygwin $append";
    print "cygwin glversion: '$make_ver'\n" if $verbose>1;
  } elsif ($^O eq 'MSWin32') {
    $make_ver = '&nmake -f makefile.mak ' . $append;
    print "MSWin32 glversion: '$make_ver'\n" if $verbose>1;
  } else {
    $make_ver = ";make -f Makefile $append";
    print "glversion: '$make_ver'\n" if $verbose>1;
  }
  my $exec = 'cd utils'."$make_ver clean".$make_ver;
  print "glversion: $exec\n" if $verbose;
  my $stat = `$exec`;
  die "Error building glversion.txt: $stat" if $?;
  print "\n$stat\n\n" if $verbose;
  unlink "utils/freeglut.dll" or die "could not remove temporary freeglut: $!" if -f "utils/freeglut.dll";
  # Parse glversion.txt file
  open GLDATA, $glv_file or die "get_gldata: could not open $glv_file: $!\n";
  my $gldata = {};
  my @gldata = <GLDATA>;
  close(GLDATA);
  foreach my $line (@gldata) {
    $line =~ s|[\r\n]+||;
    my($key,$val) = split('=',$line);
    $gldata->{$key} = $val;
  }
  die "get_gldata: no extensions found in $glv_file\n" if !keys %$gldata;
  print "This looks like OpenGL Version: $gldata->{VERSION}\n";
  if ($^O eq 'darwin') {
    $gldata->{VERSION} = '4.1';
    print "  for MacOS X, overriding to version $gldata->{VERSION}\n";
  }
  # Fix GLUT flags based on results
  if ($gldata->{FREEGLUT}) {
    print 'Found FreeGLUT v'.$gldata->{FREEGLUT}."\n";
  } elsif ($gldata->{GLUT}) {
    print "Found GLUT - Version: $gldata->{GLUT}\n";
  } else {
    print "Found no GLUT\n"
  }
  $gldata;
}

sub generate_excl {
  my ($gldata) = @_;
  # clean up previous output files
  my $exc_file = 'gl_exclude.h';
  unlink($exc_file) if (-e $exc_file);
  # Parse glext_procs.h file
  my @lines = do { open my $fh, "glext_procs.h" or die "generate_excl: could not open glext_procs.h: $!\n"; <$fh>; };
  my $no_ext = {};
  foreach my $line (@lines) {
    next if ($line !~ m|\#ifndef NO_([^\s]+)|);
    my $ext = $1;
    next if ($ext =~ m|^GL_VERSION_|);
    $no_ext->{$ext}++;
  }
  # Create gl_exclude.h
  die "Unable to write to $exc_file\n" if !open my $excl_fh, ">", $exc_file;
  print $excl_fh "// OpenGL Extension Exclusions - may be modified before building.\n";
  print $excl_fh "//\n";
  print $excl_fh "// Generated for ".$gldata->{VENDOR}.", ".$gldata->{RENDERER}."\n";
  print $excl_fh "// OpenGL v".$gldata->{VERSION}.", using ";
  print $excl_fh 'FreeGLUT v'.$gldata->{FREEGLUT}."\n" if $gldata->{FREEGLUT};
  my $GL_VERSION = $gldata->{VERSION} =~ m|^(\d\.\d+)| ? $1 : undef;
  # Make an empty exclusion file if a Windows distribution build
  print $excl_fh "\n";
  if ($GL_VERSION) {
    print $excl_fh "#define NO_GL_VERSION_4_6\n" if ($GL_VERSION < 4.6);
    print $excl_fh "#define NO_GL_VERSION_4_5\n" if ($GL_VERSION < 4.5);
    print $excl_fh "#define NO_GL_VERSION_4_4\n" if ($GL_VERSION < 4.4);
    print $excl_fh "#define NO_GL_VERSION_4_3\n" if ($GL_VERSION < 4.3);
    print $excl_fh "#define NO_GL_VERSION_4_2\n" if ($GL_VERSION < 4.2);
    print $excl_fh "#define NO_GL_VERSION_4_1\n" if ($GL_VERSION < 4.1);
    print $excl_fh "#define NO_GL_VERSION_4_0\n" if ($GL_VERSION < 4.0);
    print $excl_fh "#define NO_GL_VERSION_3_3\n" if ($GL_VERSION < 3.3);
    print $excl_fh "#define NO_GL_VERSION_3_2\n" if ($GL_VERSION < 3.2);
    print $excl_fh "#define NO_GL_VERSION_3_1\n" if ($GL_VERSION < 3.1);
    print $excl_fh "#define NO_GL_VERSION_3_0\n" if ($GL_VERSION < 3.0);
    print $excl_fh "#define NO_GL_VERSION_2_1\n" if ($GL_VERSION < 2.1);
    print $excl_fh "#define NO_GL_VERSION_2_0\n" if ($GL_VERSION < 2.0);
    print $excl_fh "#define NO_GL_VERSION_1_5\n" if ($GL_VERSION < 1.5);
    print $excl_fh "#define NO_GL_VERSION_1_4\n" if ($GL_VERSION < 1.4);
    print $excl_fh "#define NO_GL_VERSION_1_3\n" if ($GL_VERSION < 1.3);
    print $excl_fh "#define NO_GL_VERSION_1_2\n" if ($GL_VERSION < 1.2);
    print $excl_fh "#define NO_GL_VERSION_1_1\n" if ($GL_VERSION < 1.1);
  }
  foreach my $ext (split(' ',$gldata->{EXTENSIONS})) {
    next if (!$no_ext->{$ext});
    $no_ext->{$ext} = 0;
  }
  foreach my $ext (sort keys(%$no_ext)) {
    next if (!$no_ext->{$ext});
    print $excl_fh "#define NO_$ext\n";
  }
}

sub get_defines {
  my ($found_libs, $interface_lib, $incs) = @_;
  my $defs = '-DHAVE_VER';
  $defs .= " -DIS_STRAWBERRY" if $IS_STRAWBERRY;
  print "resulting libs:\n" if $verbose;
  foreach my $key (sort keys %$found_libs) {
    next if !defined $found_libs->{$key}; # defined but empty OK
    $defs .= " -DHAVE_$key";
    print "    $key = '$found_libs->{$key}'\n" if $verbose;
  }
  print "\n" if $verbose;
  $defs .= " -DHAVE_W32API" if $IS_W32API; # CYGWIN W32API
  $defs .= " -DHAVE_AGL_GLUT" if $interface_lib eq 'AGL'; # So we know we have glutWMCloseFunc() and glutCheckLoop()
  $defs .= " -Wno-deprecated-declarations" if $^O eq 'darwin';
  if (!($IS_W32API || (($^O eq 'MSWin32') && !$IS_CYGWIN)) && !($interface_lib eq 'AGL')) {
    # Test for obfuscated GLX using GL/glx.h
    my $out = cfile_text('GL/glx.h', $incs);
    if ($out =~ m|GLXContext|) {
      $defs .= " -DHAVE_GLX";
    } elsif (!$found_libs->{GLX} && $verbose) {
      print "GLX not found (neither library, nor headers).";
    }
    # Test for obfuscated Freeglut using GL/freeglut.h instead.
    $out = cfile_text('GL/freeglut.h', $INCS);
    $defs .= " -DHAVE_FREEGLUT -DHAVE_FREEGLUT_H"
      if $out =~ m|glutMainLoopEvent|;
    $defs .= " -DGL_GLEXT_LEGACY";
  }
  $defs .= " -Wno-compound-token-split-by-macro" if $^O eq 'darwin';
  $defs;
}

# Dump Config.pm
sub WriteConfigPM
{
  my($config) = @_;
  die "Unable to write to Config.pm\n" if !open my $fh, ">", "lib/OpenGL/Config.pm";
  print $fh q
{
# This is the Perl OpenGL build configuration file.
# It contains the final OpenGL build arguments from
# the configuration process.  Access the values by
# use OpenGL::Config which defines the variable
# $OpenGL::Config containing the hash arguments from
# the WriteMakefile() call.
#
};
  require Data::Dumper;
  # Ensure deterministic output
  { no warnings; $Data::Dumper::Sortkeys = 1; }
  print $fh Data::Dumper->Dump( [$config], [qw(OpenGL::Config)] );
  print $fh qq
{
1;
__END__
};
}
