use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["ts.pd",TS,PDL::Stats::TS,undef,1];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );

sub MY::postamble {pdlpp_postamble($package)};
