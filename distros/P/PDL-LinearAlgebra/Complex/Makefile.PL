
# Use this as a template for the Makefile.PL for
# any external PDL module.

use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Config;

@pack = (["complex.pd",Complex, PDL::LinearAlgebra::Complex]);

%hash = pdlpp_stdargs(@::pack);
# $hash{'OPTIMIZE'}  = '-g'; # If you want to debug, uncomment this.
#$hash{LIBS}[0] .= $^O =~ /MSWin/ ? '' : '-lacml -lgfortran ';
#$hash{LIBS}[0] .= $^O =~ /MSWin/ ? '' : '-L/usr/lib/atlas -llapack -lblas -latlas ';
#$hash{'OPTIMIZE'}  = '-O2 -mtune=k8'; # If you want to debug, uncomment this.

$hash{LIBS}[0] .= ( eval {require PkgConfig; join ' ', PkgConfig->find('lapack')->get_ldflags} ||
                    eval {require ExtUtils::PkgConfig; ExtUtils::PkgConfig->libs('lapack')} ||
                    `pkg-config lapack blas --libs` ||
                    '-L/usr/lib/atlas -llapack -lblas -latlas' ) . " -lgfortran -lquadmath";

$hash{LDLOADLIBS} .= 'oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib wsock32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib  ../lapack/libacml.lib "C:\Program Files\Microsoft Visual Studio .NET 2003\Vc7\lib\msvcrt.lib" ' if $^O =~ /MSWin/ && $Config{cc} eq 'cl';

WriteMakefile(
	%hash,
	'VERSION_FROM' => 'complex.pd',
);

# Add genpp rule
# add other makefile additions as required (see also ExtUtils::MakeMaker)
sub MY::postamble {
	pdlpp_postamble(@::pack);
}

