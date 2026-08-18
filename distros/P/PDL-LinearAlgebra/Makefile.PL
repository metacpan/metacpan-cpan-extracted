use ExtUtils::MakeMaker;
use strict;
use warnings;
use Config;
use Devel::CheckLib qw(check_lib check_lib_or_exit);
use ExtUtils::F77;
use PDL::Core::Dev;
use Text::ParseWords qw(shellwords);

my $f77_uscore = (ExtUtils::F77->trail_ ? '_' : '');
our $inc = "-DF77_USCORE=$f77_uscore";
my $fortran_checklib = <<EOF;
/* The first line must not be a preprocessor macro or Devel::CheckLib will fail
   because Devel::Checklib places this code on one line: main() { <code> }  */
#define F77_USCORE $f77_uscore
#define CONCAT_(A, B) A ## B
#define CONCAT(A, B) CONCAT_(A, B)
#define FORTRAN(name) CONCAT(name, F77_USCORE)

/* dggsvd3 is LAPACK 3.7+ which in 2026 is not supported on macOS native */
extern void FORTRAN(dggsvd3)(
  char *jobu, char *jobv, char *jobq, long *m, long *n, long *p,
  long *k, long *l, double *a, long *lda, double *b, long *ldb, double *alpha,
  double *beta, double *u, long *ldu, double *v, long *ldv,
  double *q, long *ldq, double *work, long *lwork, long *iwork, long *info);
char n = 'N';
long c_zero = 0, out_k=0, out_l=0, c_one = 1, c_m1 = -1, iwork[1], info;
double A[]={0}, B[]={0}, alpha[1], beta[1], U[1], Q[1], work[1];
/* argc is to try to stop optimiser eliminating */
if (argc < 2) FORTRAN(dggsvd3)(&n, &n, &n, &c_zero, &c_zero, &c_zero,
  &out_k, &out_l, A, &c_one, B, &c_one, alpha,
  beta, U, &c_one, NULL, &c_one,
  NULL, &c_one, work, &c_m1, iwork, &info);
return 0;
EOF
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
{
  # work around Devel::CheckLib not doing Text::ParseWords::shellwords
  my @libpath = grep -d, map {my $r=$_;$r=~s/^-L//?$r:()} my @sw = shellwords $libs0;
  my @lib = grep check_lib(lib=>$_), map {my $r=$_;$r=~s/^-l//?$r:()} @sw;
  $libs0 = join ' ', (map qq{-L"$_"}, @libpath), (map "-l$_", @lib);
  check_lib_or_exit(
    ldflags => $libs0,
    lib => 'm', # "dummy" because assert_lib wants a lib
    header => [($^O =~ /MSWin/ ? 'float.h' : ()), qw(stdio.h math.h)],
    function => $fortran_checklib,
  );
}

my $preop = '$(PERLRUNINST) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)';
my $package_name = "PDL::LinearAlgebra";
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  NAME => 'PDL::LinearAlgebra',
  ABSTRACT => 'PDL bindings to some BLAS and LAPACK library routines',
  AUTHOR => [ 'Grégory Vanuxem <ellipse@cpan.org>' ],
  VERSION_FROM => 'lib/PDL/LinearAlgebra.pm',
  LICENSE => 'artistic_2',
  MIN_PERL_VERSION => '5.016',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>"https://github.com/$repo/issues"},
      repository  => {
        url => "git://github.com/$repo.git",
        type => 'git',
        web => "https://github.com/$repo",
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  CONFIGURE_REQUIRES =>  {
    "PDL" => '2.105',
    "Devel::CheckLib" => '1.16', # argc is not supplied in 1.05, but 1.16 works.
    "ExtUtils::F77" => '1.26',
  },
  PREREQ_PM => {
    "PDL" => '2.105', # pdldoc_add
  },
  TEST_REQUIRES =>  {
    "Test::More" => '0.88', # done_testing
  },
  INC => $inc,
  LIBS => [$libs0],
  dist => { COMPRESS => 'gzip', SUFFIX => 'gz', PREOP => $preop },
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
  for my $pkg (qw(openblas lapack)) {
    my $pref = `brew --prefix $pkg`;
    chomp $pref;
    next if !$pref or !-d $pref; # --prefix is where is *or would be* installed
    return qq{-L"$pref/lib" -llapack -lblas};
  }
  ();
}

my @pd_srcs;
sub MY::init_PM {
  package MY; # so that "SUPER" works right
  my ($self) = @_;
  $self->SUPER::init_PM;
  delete $self->{PM}{'pp_defc.pl'};
  @pd_srcs = ::pdlpp_eumm_update_deep($self);
}
sub MY::postamble { pdlpp_postamble(@pd_srcs) . pdldoc_add() }
