use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use ExtUtils::F77;
use Devel::CheckLib;
use Config;
my $f77 = 'ExtUtils::F77';
die "No fortran compiler found. Will not build PDL::Opt::QP on this system\n" if !$f77->testcompiler;

# from PDL::Opt::NonLinear
my @pack = qw(qp.pd QP PDL::Opt::QP);
my @ffiles = map {s/\.f$//; $_} glob("*.f");
my $fobj = join ' ', map {"$_\$(OBJ_EXT)"} @ffiles;
my %hash = pdlpp_stdargs(\@pack);
$hash{OBJECT} .= " $fobj";
$hash{LIBS}[0] .= $f77->runtime . ' -lblas' ;
$hash{clean}{FILES} .= " $fobj";

# from PDL::LinearAlgebra
our $inc = '-DF77_USCORE='. ($f77->trail_ ? '_' : '');
$hash{INC} .= " $inc";
our %ldloadlibs = ($^O =~ /MSWin/ && $Config{cc} eq 'cl')
  ? (LDLOADLIBS => 'oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib
 comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid
.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.l
ib  ../lapack/libacml.lib "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc
7\lib\msvcrt.lib" ')
  : ();
my @pkgs = qw(lapack blas);
our $libs0 = (
  eval {require PkgConfig; join ' ', map PkgConfig->find($_)->get_ldflags, @pkgs} ||
  eval {require ExtUtils::PkgConfig; join ' ', map ExtUtils::PkgConfig->libs($_), @pkgs} ||
  find_libs() ||
  `pkg-config @pkgs --libs` ||
  '-L/usr/lib/atlas -llapack -lblas -latlas'
) . ' ' . ExtUtils::F77->runtime;
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
$hash{LIBS}[0] .= " $libs0";

WriteMakefile(
  %hash,
  %ldloadlibs,
  LICENSE           => 'perl',
  'CONFIGURE_REQUIRES' =>  {
    "PDL" => '2.063',
    "ExtUtils::F77" => 0,
    "Devel::CheckLib" => 0,
  },
  'PREREQ_PM' => {
    'PDL' => '2.063',
  },
  TEST_REQUIRES => {
      'Test::More'      => '0.88',
      'Test::Exception' => 0,
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository  => {
        url => 'git://github.com/mvgrimes/pdl-opt-qp.git',
        type => 'git',
        web => 'https://github.com/mvgrimes/pdl-opt-qp',
      },
      bugtracker => {web=>'https://github.com/mvgrimes/pdl-opt-qp/issues'},
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
);

sub MY::postamble {
        my $mycompiler     = $f77->compiler;
        my $mycflags       = $f77->cflags;
        my $orig = pdlpp_postamble(\@pack);
        $orig =~ s/:\s*qp\.pd/: qp.pd/;
        $orig .= <<EOF;

FC = $mycompiler
FFLAGS = $mycflags -O3 -fPIC

EOF
        $orig .join "",map {
("
$_\$(OBJ_EXT): $_.f
\t\$(FC) -c -o \$@ \$(FFLAGS) \$<
" )} @ffiles;
}

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
