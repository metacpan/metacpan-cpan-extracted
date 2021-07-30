use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use Data::Dumper;

use PDL::Core::Dev;

my $PL_MAJOR = 5; # minimum required
my $PL_MINOR = 15;

unlink ("OPTIONS!"); # remove file used to communicate with plplot.pd

my $libbasename;
my $libname;
my $plplot_lib_path;

foreach ('plplot') {
  # on OS-X the library is called libplplot.dylib, so we
  # use $Config{"so"} to get the extension name
  #
  $libbasename = $_;
  $libname = "lib${libbasename}." . $Config{"so"};
  my $libname_static = "lib{$libbasename}.a";
  foreach my $libdir (
              split(' ', $Config{libpth}), # not perl-in-space friendly
              $ENV{PLPLOT_LIBDIR},
              '/usr/local/plplot/lib64',
                      '/usr/local/plplot/lib',
              '/usr/local/lib64',
              '/usr/local/lib',
              '/opt/local/lib',
              '/usr/lib64',
              '/usr/lib',
              '/opt/lib64',
              '/opt/lib',
              '/ops/tools/lib',
                      '/sw/lib/',    # default FINK installation
                            # Add new library paths here!!
              ) {

    if (-e "$libdir/$libname") {
      $plplot_lib_path = $libdir;
      $ENV{LD_LIBRARY_PATH} .= ":$libdir";
      last;
    } elsif (-e "$libdir/$libname_static") {
      $plplot_lib_path = $libdir;
      $ENV{LD_LIBRARY_PATH} .= ":$libdir";
      $libname = $libname_static;
      last;
    }

  }

  if (defined $plplot_lib_path) {
      last;
  }
}

unless (defined ($plplot_lib_path)) {
  die "Cannot find plplot library $libname\n";
}

my $incname = "plplot.h";
my $plplot_include_path;

foreach my $incdir (
		    $ENV{PLPLOT_INCDIR} || (),
                    '/usr/local/plplot/include',
                    '/usr/local/plplot/include/plplot',
		    '/usr/local/include/plplot',
		    '/usr/local/include',
		    '/opt/local/include',
		    '/usr/include',
		    '/usr/include/plplot',
		    '/opt/include',
		    '/ops/tools/include/plplot',
		    '/ops/tools/include',
                    '/sw/include/plplot/',    # default FINK installation
		                  # Add new header paths here!!
		    ) {

  if (-e "$incdir/$incname") {
    $plplot_include_path = "-I$incdir";
    if ($incdir =~ m|/plplot$|) {
      my $inc2 = $incdir;
      $inc2 =~ s|/plplot$||;
      $plplot_include_path .= " -I$inc2";
    }
    last;
  }
}

unless (defined ($plplot_include_path)) {
  die "Cannot find plplot header file ($incname)\n";
}

# Try linking with library.  New if blocks should be added if necessary
my $libs;
foreach my $l (
	       "-L$plplot_lib_path -l${libbasename} -lX11",
	       "-L$plplot_lib_path -l${libbasename}",
             "-L$plplot_lib_path -l${libbasename} -lqsastime -lcsirocsa -lgdi32 -lcomdlg32",
	       # New lib combinations should be added here!
	       ) {
  if (trylink( '', '#include <plplot.h>', 'plinit();', "$l $plplot_include_path")) {
    $libs = $l;
    last;
  }
}

unless (defined($libs)) {
  die "Cannot find good set of libraries for linking PLplot\n";
}

# Test that PLplot was compiled --with-double (IE, a PLFLT is a double)
my $size = compileAndRun ("$plplot_include_path $libs", 1, <<'EOC');
#include <plplot.h>
main () {  printf  ("%d", sizeof (PLFLT)); }
EOC

unless ($size == 8) {
  die <<'EOF';
Sizeof(PLFLT) must be 8.
PLplot must be compiled --with-double (IE ./configure --with-double).
EOF
}

my $plgver = compileAndRun ("$plplot_include_path $libs", 1, <<'EOC');
#include <plplot.h>
main () {
  char ver[80];
  c_plgver(ver);
  fputs(ver, stdout);
}
EOC
my @plver = split /\./, $plgver;
unless ($plver[0] > $PL_MAJOR or ($plver[0] == $PL_MAJOR and $plver[1] >= $PL_MINOR)) {
  die "Insufficient plplot version '$plgver'; need at least $PL_MAJOR.$PL_MINOR\n";
}

my %plversion = ();
$plversion{'C_COMPILE'}   = "$Config{cc} $Config{ccflags} $plplot_include_path";
$plversion{'C_COMPILE_SUFFIX'} = $libs;
$plversion{'PLPLOT_LIB'}  = $plplot_lib_path;
# Write these options to a file--used during the test step
open my $fh, '>', 'OPTIONS!' or die "Cannot write to OPTIONS! file";
print  {$fh} Dumper(\%plversion);
close   $fh;

my @pack = ([qw(plplot.pd PLplot PDL::Graphics::PLplot)]);

my %hash = pdlpp_stdargs(@pack);
$hash{'PREREQ_PM'} = { PDL => 0 };
$hash{CONFIGURE_REQUIRES} = {
  'PDL::Core::Dev' => 0,
};
# $hash{'OPTIMIZE'}  = '-g'; # If you want to debug, uncomment this.
$hash{TEST_REQUIRES} = {
  'Test::More' => '0.88', # done_testing
};
$hash{'VERSION_FROM'}   = 'plplot.pd';
$hash{'LIBS'}      = [$libs];
$hash{'INC'}      .= " $plplot_include_path";
$hash{clean}{FILES} .= ' *svg.* *.xfig temp* OPTIONS!';
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker  => {web=>'https://github.com/PDLPorters/pdl-graphics-plplot/issues'},
    repository  => {
       url => 'git://github.com/PDLPorters/pdl-graphics-plplot.git',
       type => 'git',
       web => 'https://github.com/PDLPorters/pdl-graphics-plplot',
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
};

my $postamble = pdlpp_postamble(@pack);

WriteMakefile(%hash);

# Add genpp rule
sub MY::postamble { $postamble };

sub compileAndRun {
  my $flags = shift;
  my $run   = shift;
  my $code  = shift;

  open (OUT, ">temp.c");
  print OUT $code;
  close OUT;
  unlink './temp'; # since we work out whether the compile succeeds by presence of this
  unlink './temp.exe'; # since we work out whether the compile succeeds by presence of this

  my $cc = $Config{cc};
  my $ccflags = $Config{ccflags};
  # print "Trying: $cc $ccflags $flags temp.c -o temp\n";

  # The duplication of $flags seems to be necessary, as some systems
  # need $flags before temp.c and some after.  D. Hunt 2/9/2011
  my $devnull = File::Spec->devnull();
  system "$cc $ccflags $flags temp.c $flags -o temp > $devnull 2>&1";
  unlink('./temp.c');
  die "Cannot compile test program: $code" unless (-e 'temp' or -e 'temp.exe');
  return unless ($run);

  my $res = `./temp`;
  unlink ('./temp');
  return $res;
}
