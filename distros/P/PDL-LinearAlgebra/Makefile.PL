use ExtUtils::MakeMaker;
use Config;

our %ldloadlibs = ($^O =~ /MSWin/ && $Config{cc} eq 'cl')
  ? (LDLOADLIBS => 'oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib  ../lapack/libacml.lib "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\lib\msvcrt.lib" ')
  : ();
our $libs0 = (
  eval {require PkgConfig; join ' ', PkgConfig->find('lapack')->get_ldflags} ||
  eval {require ExtUtils::PkgConfig; ExtUtils::PkgConfig->libs('lapack')} ||
  `pkg-config lapack blas --libs` ||
  '-L/usr/lib/atlas -llapack -lblas -latlas'
) . " -lgfortran -lquadmath";

WriteMakefile(
  NAME => 'PDL::LinearAlgebra',
  ABSTRACT => 'PDL bindings to some BLAS and LAPACK library routines',
  AUTHOR => [ 'Chris Marshall <chm@cpan.org>' ],
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
    "PDL" => 0,
  },
  PREREQ_PM => {
    "PDL" => '2.047', # ci() -> i()
  },
  TEST_REQUIRES =>  {
    "Test::More" => '0.88', # done_testing
  },
  dist => { PREOP=>'$(PERL) -MPDL::Core::Dev -e pdlpp_mkgen $(DISTVNAME)' }, # GENERATED subdir in dist tarball
  clean => { FILES => '*~' },
);
