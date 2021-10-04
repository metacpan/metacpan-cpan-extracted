use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["glm.pd",GLM,PDL::Stats::GLM,undef,1];
%hash = pdlpp_stdargs($package); 

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
