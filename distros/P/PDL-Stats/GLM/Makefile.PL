use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

use PDL;

if ($PDL::VERSION =~ /^2\.4\.7/) {
    warn "PDL::Stats::GLM has known issue with PDL-2.4.7. Please update PDL and retry installation.\n";
    exit;
}

$package = ["glm.pd",GLM,PDL::Stats::GLM];
%hash = pdlpp_stdargs($package); 

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
