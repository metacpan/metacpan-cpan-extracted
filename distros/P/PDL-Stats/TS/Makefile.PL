use PDL::Core::Dev;
use ExtUtils::MakeMaker;

$package = ["ts.pd",TS,PDL::Stats::TS,undef,1];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash, NO_MYMETA => 1 );

sub MY::postamble {pdlpp_postamble($package)};
