use strict;
use warnings;

use ExtUtils::MakeMaker;
use PDL::Core::Dev;
 
$package = ["util.pd",Util,Statistics::Descriptive::PDL::Util];
%hash = pdlpp_stdargs($package);

WriteMakefile( %hash );
 
sub MY::postamble {pdlpp_postamble($package)};
