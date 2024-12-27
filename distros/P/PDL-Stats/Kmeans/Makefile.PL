use PDL::Core::Dev;
use ExtUtils::MakeMaker;

$package = ["kmeans.pd",Kmeans,PDL::Stats::Kmeans,undef,1];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash, NO_MYMETA => 1 );

sub MY::postamble {pdlpp_postamble($package)};
