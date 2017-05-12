use File::Basename;
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$common::x = "$ENV{X11ROOT}/XFree86"
  if exists $ENV{X11ROOT} and -d "$ENV{X11ROOT}/XFree86/lib" and -d "$ENV{X11ROOT}/XFree86/include";

$try_libs = $common::x ? "-L$common::x/lib" : '';
$try_libs .= ' -L/usr/openwin/lib -lX11 -lm -lsocket -lvga -llinuxvga -lgd -lpng -ljpeg -lfreetype -lz -ljmgraph -lvesa -lpdf';

@ARGV = grep !(/^TRY_LIBS=(.*)$/ and $try_libs = $1), @ARGV;

use Config;

my (%libs, %symb);
{
  print "...Looking for libs, expect some warnings...\n";
  my $loadlibs;
  if ($] >= 5.008001) {
    require ExtUtils::Liblist;          # Buggy before this
    ($loadlibs) = ExtUtils::Liblist->ext( $try_libs );
  } else {
    push @INC, 'utils';
    require FindLib;
    $loadlibs = FindLib::findlib( $try_libs );
  }

  print "...Found libs: '$loadlibs'\n";
  my (@libs) = ($loadlibs =~ /\B-l(\S*)/g);
  @libs{@libs} = @libs;
  my %funcs = ( gd  => [qw(trygd.h  gd.h  gdImageCreate gdImageGif
					  gdImageJpeg gdImageStringFT
					  gdImageStringTTF gdImagePng)],
		png => [qw(trypng.h png.h png_read_image detected_PNGversion89
					  png_create_write_struct)],
		pdf => [qw(trypdf.h pdflib.h PDF_get_majorversion
					     PDF_begin_pattern)],
	      );
  if (not $libs{z} and $libs{gd}) {
    print "-lz not found, required for -lgd\n";
    delete $libs{gd};
  }
  for my $l (keys %funcs) {
    my($have, $in);
    print "-l$l not found\n", next unless $libs{$l};
    my @symb = @{$funcs{$l}};
    my $header = shift @symb;
    my $header1 = shift @symb;
    # Need to check for functions, if not found, abort...  How?!!!
    my $cppflags = $Config{cppflags};
    $cppflags =~ s/-Zmt\b// if $^O eq 'os2';	# Better fixed in Configure...
  # Use $Config{cpprun}, instead of $Config{cpp}. cpp is simply set to
  # 'cpp' after Configure has run, which is not useful, since it lives
  # in /lib/ on many systems, which is normally not on the path.  This
  # is documented, but silly behaviour.  $Config{cpprun} is what is
  # documented to be set to a cpp that will take stuff on stdin
    my $cpp = $Config{cpprun} || $Config{cpp};
    my $cmd = "$cpp $cppflags $header";
    my %this_symb;
    if (open IN, "$cmd |") {{
      local $/;
      $in = <IN>;
      close IN or (warn("close pipe from `$cmd': $!"), last);
      for my $s (@symb) {
	$this_symb{$s}++, $symb{$s}++, $have++ if $in =~ /$s/;
      }
    }}
    if ($have) {
      my @s = sort keys %this_symb; 
      print "...Found @s (out of @symb) in $header1, keeping -l$l.\n";
    } else {
      $loadlibs =~ s/-l\Q$l\E\b//g; # //g just in case
      $try_libs =~ s/-l\Q$l\E\b//g; # //g just in case
      print "...Could not find @symb in $header1, removing -l$l.\n";
    }
  }
  $common::loadlibs = $loadlibs;
}
$common::try_libs = $try_libs;

$common::pm_exe = 'gplpmdrb';			# Usual: gnupmdrv
$common::x_exe = 'gnuplot_x11b';		# Usual: without b
$common::defines = '-DPM3D -DUSE_ULIG_FILLEDBOXES -DUSE_ACTIVE_EVENTS';

my $png;
$common::defines .= ' -DHAVE_LIBPNG', $png++
   if $symb{png_create_write_struct} and $symb{detected_PNGversion89};
$common::defines .= ' -DHAVE_LIBGD'		if $symb{gdImageCreate};
$common::defines .= ' -DHAVE_GD_GIF -DHAVE_GIF'	if $symb{gdImageGif}; # new/old
$common::defines .= ' -DHAVE_GD_JPEG'		if $symb{gdImageJpeg}
							and $libs{jpeg};
my $gd_png;
$common::defines .= ' -DHAVE_GD_PNG -DHAVE_NEWGD -DHAVE_PNG', $gd_png++
   if $symb{gdImagePng}	and $libs{png};
$common::defines .= ' -DgdImageStringFT=gdImageStringTTF'
	if $symb{gdImageStringTTF} and not $symb{gdImageStringFT};
$common::defines .= ' -DHAVE_GD_TTF'
	if ($symb{gdImageStringTTF} or $symb{gdImageStringFT})
							and $libs{freetype};
if ($symb{PDF_get_majorversion}) {
  $common::defines .= ' -DHAVE_LIBPDF';
  $common::defines .= ' -DHAVE_OLD_LIBPDF' unless $symb{PDF_begin_pattern};
}


# No IPC is needed without mouse enabled
if ($^O eq 'os2') {
 # $common::defines .= ' -DOS2_IPC';
} else {
 # $common::defines .= ' -DPIPE_IPC';
}

$common::cflags = '';

# Not used: inline, STDC_HEADERS, NOCWDRC, HAVE_ERF, HAVE_GAMMA,
# HAVE_GETCWD, HAVE_LGAMMA, HAVE_SETVBUF, HAVE_SYSINFO, HAVE_TCGETATTR, 
# HAVE_SGTTY_H, HAVE_SYS_BSDTYPES_H, HAVE_SYS_SYSTEMINFO_H

# Cannot find: DOS32, EXTERN_ERRNO, HAVE_LIBGD, HAVE_LIBPNG, LINUXVGA,
# MSDOS, NO_ERRNO_H, READLINE, X11, HAVE_SLEEP, 

# Cannot find, probably important: NO_ATEXIT, HAVE_ON_EXIT, PIPES, HAVE_LIBC_H
$common::cflags .= ' -DNO_STDLIB_H' unless $Config{i_stdlib};	# not used now
$common::cflags .= ' -DNO_FLOAT_H' unless $Config{i_float};

$common::cflags .= ' -DHAVE_UNISTD_H' if $Config{i_unistd};
$common::cflags .= ' -DHAVE_FLOAT_H'  if $Config{i_float};
$common::cflags .= ' -DHAVE_LIMITS_H' if $Config{i_limits};
$common::cflags .= ' -DHAVE_LOCALE_H' if $Config{i_locale};
$common::cflags .= ' -DHAVE_MATH_H'   if $Config{i_math};
$common::cflags .= ' -DHAVE_MALLOC_H'   if $Config{i_malloc};
$common::cflags .= ' -DHAVE_STDLIB_H' if $Config{i_stdlib};
$common::cflags .= ' -DHAVE_UNISTD_H' if $Config{i_unistd};
$common::cflags .= ' -DHAVE_STRING_H' if $Config{i_string};
$common::cflags .= ' -DHAVE_TERMIOS_H' if $Config{i_termios};
$common::cflags .= ' -DHAVE_VALUES_H' if $Config{i_values};
$common::cflags .= ' -DHAVE_SYS_TYPES_H' if $Config{i_systypes};
$common::cflags .= ' -DHAVE_SYS_STAT_H' if $Config{i_sysstat};
$common::cflags .= ' -DHAVE_SYS_PARAM_H' if $Config{i_sysparam};

if ($Config{i_time} or $Config{timeincl} and $Config{timeincl} =~ /\W/) {
  $common::cflags .= ' -DHAVE_TIME_H'	# Is it reasonable?
} else {
  $common::cflags .= ' -DNO_TIME_H'	# Is it reasonable?
}

$common::cflags .= ' -DOLD_SELECT' unless $Config{i_sysselct};
$common::cflags .= ' -DNO_MEMCPY' unless $Config{d_memcpy};
$common::cflags .= ' -DHAVE_MEMCPY' if $Config{d_memcpy};
$common::cflags .= ' -DNO_MEMSET' unless $Config{d_memset};
$common::cflags .= ' -DHAVE_MEMSET' if $Config{d_memset};
$common::cflags .= ' -DNO_STRCHR' unless $Config{d_strchr};
# 	Assume that STRSTR and STRCHR are present simultaneously:
$common::cflags .= ' -DHAVE_STRCHR -DHAVE_STRSTR' if $Config{d_strchr};
$common::cflags .= ' -DHAVE_STRERROR' if $Config{d_strerror};
$common::cflags .= ' -DANSI_C' if $Config{'prototype'}; # Will -DPROTOTYPES automatically
$common::cflags .= ' -Dconst=' unless $Config{d_const};
$common::cflags .= ' -DNOCOPY' unless $Config{d_bcopy};
$common::cflags .= ' -Dsize_t=unsigned' unless $Config{sizetype} eq 'size_t';
$common::cflags .= ' -Dtime_t=long' unless $Config{timetype} eq 'time_t';

# $common::cflags .= ' -DGETCWD -DHAVE_STRNICMP -DPIPES -DHAVE_STRERROR -DNOGAMMA' if $^O eq 'os2';
if ($^O eq 'os2' or $^O eq 'MSWin32') {
  $common::cflags .= ' -DHAVE_STRNICMP';
} else {
  $common::cflags .= ' -DHAVE_STRNCASECMP';
}
# on MSWin32 this header is a wrapper available in Perl CORE only
$common::cflags .= ' -DHAVE_DIRENT_H' if $Config{i_dirent} and $^O ne 'MSWin32';

$gnuplotdir = './gnuterm';

WriteMakefile(
    'NAME'	=> 'Term::Gnuplot',
    'DEFINE'	=> $common::defines,
    'VERSION_FROM'	=> 'Gnuplot.pm',
    'MYEXTLIB'	=> $gnuplotdir . '/libgnuterm$(LIB_EXT)',
    'LIBS'	=> [ $try_libs ],
    #'LIBS'	=> [' -L/usr/openwin/lib -lX11 -lm  -lsocket -L. -lgnuterm'],
    #'LIBS'	=> [' -L/usr/openwin/lib -lX11 -lm  -lsocket '
    #		    . "-L$gnuplotdir -lgnuplot"],   # e.g., '-lm' 
    'INC'	=> "-I$gnuplotdir",     # e.g., '-Idir' 
    #'DEFINE'	=> '-DNO_JUNK',     # e.g., '-DHAVE_SOMETHING' 
# bz2 is not yet supported by CPAN.pm and PAUSE indexer in 2005
#    'dist' => {COMPRESS=>'bzip2 -f', SUFFIX=>'bz2'},
	 # Let us hope that boot_Term__Gnuplot should not be mangled
    'FUNCLIST'	=> ['get_term_ftable', 'boot_Term__Gnuplot'],
    #clean     => { FILES    => 'test_x11' },
);

sub MY::postamble {
  my $self = shift;
"GNUPLOT_DIR = $gnuplotdir" .   '

$(MYEXTLIB)  : FORCE
	cd $(GNUPLOT_DIR); make libgnuterm$(LIB_EXT) $(PASTHRU)

gnuterm_dynamic  : FORCE
	cd $(GNUPLOT_DIR); make dynamic $(PASTHRU)

';
}

# This subroutine disappeared at some version of perl...
sub MY::_maybe_command_in_dirs {	# $ver is optional argument if looking for perl
# Ilya's suggestion. Not yet used, want to understand it first, but at least the code is here
    my($self, $names, $dirs, $trace, $ver) = @_;
    my($name, $dir);
    foreach $dir (@$dirs){
	next unless defined $dir; # $self->{PERL_SRC} may be undefined
	foreach $name (@$names){
	    my($abs,$tryabs);
	    if ($self->file_name_is_absolute($name)) { # /foo/bar
		$abs = $name;
	    } elsif ($self->canonpath($name) eq $self->canonpath(basename($name))) { # bar
		$abs = $self->catfile($dir, $name);
	    } else { # foo/bar
		$abs = $self->catfile($self->curdir, $name);
	    }
	    print "Checking $abs for $name\n" if ($trace >= 2);
	    next unless $tryabs = $self->maybe_command($abs);
	    print "Substituting $tryabs instead of $abs\n"
		if ($trace >= 2 and $tryabs ne $abs);
	    $abs = $tryabs;
	    if (defined $ver) {
		print "Executing $abs\n" if ($trace >= 2);
		if (`$abs -e 'require $ver; print "VER_OK\n" ' 2>&1` =~ /VER_OK/) {
		    print "Using PERL=$abs\n" if $trace;
		    return $abs;
		}
	    } else { # Do not look for perl
		return $abs;
	    }
	}
    }
}
