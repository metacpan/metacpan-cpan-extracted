use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "pdlmaker.plm";

$package  = ["HMM.pd",HMM,PDL::HMM];
%hash = pdlmaker_init($package);

my %prereq = (
	      PDL=>0,
	      'Test::More'=>0,
	     );

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'PDL Hidden Markov Model utilities';
$hash{PREREQ_PM} = {%prereq};
$hash{CONFIGURE_REQUIRES} = {%prereq,'ExtUtils::MakeMaker'=>0};
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
##
$hash{VERSION_FROM} = 'HMM.pd';
##
$hash{realclean}{FILES} .= ' *~ *.tmp README.txt';

WriteMakefile(%hash);
