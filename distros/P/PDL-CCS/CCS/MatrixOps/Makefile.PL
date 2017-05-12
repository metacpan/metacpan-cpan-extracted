use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "../../pdlmaker.plm";

$package = ["ccsmatops.pd", 'MatrixOps', 'PDL::CCS::MatrixOps'];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Low-level matrix operations for compressed storage sparse PDLs';
$hash{VERSION_FROM} = '../../CCS.pm';
$hash{LICENSE} = 'perl';
$hash{PREREQ_PM}{PDL} = $hash{CONFIGURE_REQUIRES}{PDL} = 0;
push(@{$hash{LIBS}}, '-lm');
$hash{DIR} = [];
#$hash{INC} .= '';
#$hash{OBJECT} .= '';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

#my $pmfile = $package[0];
#$pmfile =~ s/\.pd$/\.pm/;
#$hash{PM}{$pmfile} = "\$(INST_LIBDIR)/CCS/$pmfile";

WriteMakefile(%hash);
