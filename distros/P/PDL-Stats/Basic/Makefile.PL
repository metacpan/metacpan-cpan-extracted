use ExtUtils::MakeMaker;
use PDL::Core::Dev;

$package = ["stats_basic.pd",Basic,PDL::Stats::Basic,undef,1];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
