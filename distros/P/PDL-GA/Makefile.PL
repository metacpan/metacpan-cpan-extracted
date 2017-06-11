use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

use lib '.'; ##-- fix RT bug #121661?
require "pdlmaker.plm";

$package = ["GA.pd",GA,PDL::GA];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Genetic algorithm utilities for PDL';

$hash{PREREQ_PM} = {PDL=>0};
$hash{CONFIGURE_REQUIRES} = {PDL=>0,'ExtUtils::MakeMaker'=>0};

push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
$hash{VERSION_FROM} = 'GA.pd';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
