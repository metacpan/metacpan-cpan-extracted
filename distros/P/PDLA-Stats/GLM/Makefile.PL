use PDLA::Core::Dev;
use ExtUtils::MakeMaker;
PDLA::Core::Dev->import();

use PDLA;

if ($PDLA::VERSION =~ /^2\.4\.7/) {
    warn "PDLA::Stats::GLM has known issue with PDLA-2.4.7. Please update PDLA and retry installation.\n";
    exit;
}

$package = ["glm.pp",GLM,PDLA::Stats::GLM];
%hash = pdlpp_stdargs($package); 

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
