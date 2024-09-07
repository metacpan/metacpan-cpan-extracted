use ExtUtils::MakeMaker;
use Config;
use Devel::CheckLib qw(check_lib check_lib_or_exit);
use ExtUtils::F77;
use PDL::Core::Dev;

our %ldloadlibs = ($^O =~ /MSWin/ && $Config{cc} eq 'cl')
  ? (LDLOADLIBS => 'oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib  ../lapack/libacml.lib "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\lib\msvcrt.lib" ')
  : ();
my @pkgs = qw(lapack blas);
our $libs0 = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  find_macos_libs() ||
  find_libs() ||
  `pkg-config @pkgs --libs` ||
  '-L/usr/lib/atlas -llapack -lblas -latlas'
) . ' ' . ExtUtils::F77->runtime;
our $inc = '-DF77_USCORE='. (ExtUtils::F77->trail_ ? '_' : '');
{
  # work around Devel::CheckLib not doing Text::ParseWords::shellwords
  use Text::ParseWords qw(shellwords);
  my @libpath = grep -d, map {my $r=$_;$r=~s/^-L//?$r:()} my @sw = shellwords $libs0;
  my @lib = grep check_lib(lib=>$_), map {my $r=$_;$r=~s/^-l//?$r:()} @sw;
  $libs0 = join ' ', (map qq{-L"$_"}, @libpath), (map "-l$_", @lib);
  my $f77_uscore = (ExtUtils::F77->trail_ ? '_' : '');
  check_lib_or_exit(
    ldflags => $libs0,
    header => [($^O =~ /MSWin/ ? 'float.h' : ()), qw(stdio.h math.h)],
    function => <<EOF,

#define F77_USCORE $f77_uscore
#define CONCAT_(A, B) A ## B
#define CONCAT(A, B) CONCAT_(A, B)
#define FORTRAN(name) CONCAT(name, F77_USCORE)

long c_zero = 0;
long c_nine = 9;
extern long FORTRAN(ilaenv)(long *ispec, char *name__, char *opts, long *n1,
  long *n2, long *n3, long *n4, long name_len, long opts_len);
long i = FORTRAN(ilaenv)(&c_nine, "SGESDD", " ", &c_zero, &c_zero, &c_zero, &c_zero, 6, 1);
if (argc > 2) printf("%ld", i); /* try to stop optimiser eliminating */
EOF
  );
}

WriteMakefile(
  NAME => 'PDL::LinearAlgebra',
  ABSTRACT => 'PDL bindings to some BLAS and LAPACK library routines',
  AUTHOR => [ 'Grégory Vanuxem <ellipse@cpan.org>' ],
  VERSION_FROM => 'lib/PDL/LinearAlgebra.pm',
  LICENSE => 'artistic_2',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      repository  => {
        url => 'git://github.com/PDLPorters/pdl-linearalgebra.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/pdl-linearalgebra',
      },
      bugtracker => {web=>'https://github.com/PDLPorters/pdl-linearalgebra/issues'},
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
  CONFIGURE_REQUIRES =>  {
    "PDL" => '2.091',
    "Devel::CheckLib" => 0,
    "ExtUtils::F77" => '1.26',
  },
  PREREQ_PM => {
    "PDL" => '2.091', # tricpy etc
  },
  TEST_REQUIRES =>  {
    "Test::More" => '0.88', # done_testing
  },
  dist => { PREOP=>'$(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' }, # GENERATED subdir in dist tarball
  clean => { FILES => '*~' },
);


sub find_libs {
  return if $^O !~ /linux/i;
  # in performance order based on libraries I've used
  # for xnec2c in Ubuntu, Debian, SuSE, CentOS, etc.
  # See comments here for detail:
  #    https://github.com/KJ7LNW/xnec2c/blob/master/src/mathlib.c#L29
  my @libs = qw/
    openblaso
    openblas_openmp
    openblasp
    openblas_pthreads
    openblas
    openblas_serial
    mkl_rt/;
  for my $l (@libs) {
    return "-l$l" if (check_lib(lib => $l));
  }
  return;
}

sub find_macos_libs {
  return if $^O ne 'darwin';
  my $pref = `brew --prefix lapack`;
  return if !$pref;
  chomp $pref;
  qq{-L"$pref/lib" -llapack -lblas};
}

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
