use ExtUtils::MakeMaker;
use PDL::Core::Dev;

our (%ldloadlibs, $libs0, $inc);
my $pkg = 'Trans';
my $file = lc($pkg).".pd";
my @pack = ([$file, $pkg, "PDL::LinearAlgebra::$pkg",undef,1]);
my %hash = pdlpp_stdargs(@pack);
$hash{LIBS}[0] .= $libs0;
$hash{OBJECT} .= ' selectfunc$(OBJ_EXT)';
$hash{INC} .= " $inc";

WriteMakefile(
	%hash,
	%ldloadlibs,
	VERSION_FROM => $file,
	NO_MYMETA => 1,
);

sub MY::postamble {
	pdlpp_postamble(@pack);
}
