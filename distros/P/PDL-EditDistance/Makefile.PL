use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "pdlmaker.plm";

$package = ["EditDistance.pd",EditDistance,PDL::EditDistance];
%hash = pdlmaker_init($package);

##-- preqrequistes (for PREREQ_PM)
my %prereq = (
	      'PDL' => 0, #'2.4.2',
	      'ExtUtils::MakeMaker' => 0,
	      'Test::More' => 0,
	     );


$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Compute Wagner-Fischer edit distance and alignment matrices on PDLs';
$hash{PREREQ_PM} = {%prereq};
$hash{CONFIGURE_REQUIRES} = {%prereq};
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
$hash{VERSION_FROM} = 'EditDistance.pd';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
