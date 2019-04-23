use ExtUtils::MakeMaker;
use PDLA::Core::Dev;

$package = ["stats_basic.pd",Basic,PDLA::Stats::Basic];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
