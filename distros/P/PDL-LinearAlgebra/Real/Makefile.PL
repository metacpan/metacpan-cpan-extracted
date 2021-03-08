use ExtUtils::MakeMaker;
use PDL::Core::Dev;

our (%ldloadlibs, $libs0);
my $pkg = 'Real';
my $file = lc($pkg).".pd";
my @pack = ([$file, $pkg, "PDL::LinearAlgebra::$pkg"]);
my %hash = pdlpp_stdargs(@pack);
$hash{LIBS}[0] .= $libs0;

WriteMakefile(
	%hash,
	%ldloadlibs,
	'VERSION_FROM' => $file,
);

sub MY::postamble {
	pdlpp_postamble(@pack);
}
