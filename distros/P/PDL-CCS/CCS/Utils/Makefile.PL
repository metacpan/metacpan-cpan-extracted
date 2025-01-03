use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "../../pdlmaker.plm";

$package = ["ccsutils.pd", 'Utils', 'PDL::CCS::Utils'];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Low-level utilities for compressed storage sparse PDLs';
$hash{VERSION_FROM} = '../../CCS.pm';
$hash{LICENSE} = 'perl';
$hash{PREREQ_PM}{PDL} = $hash{CONFIGURE_REQUIRES}{PDL} = 0;
push(@{$hash{LIBS}}, '-lm');
$hash{DIR} = [];
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);

