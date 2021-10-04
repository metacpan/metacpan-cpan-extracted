use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["kmeans.pd",Kmeans,PDL::Stats::Kmeans,undef,1];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
