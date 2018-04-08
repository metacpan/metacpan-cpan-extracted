use PDL::Core::Dev;
use ExtUtils::MakeMaker;

##-- pdlmaker stuff
PDL::Core::Dev->import();
require "./pdlmaker.plm";

$package = ["Cluster.pd",Cluster,PDL::Cluster];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Perl interface to the C Clustering Library with PDL support';
$hash{VERSION_FROM} = 'Cluster.pd';
$hash{PREREQ_PM} = {
		    'PDL' => 0,
		    'Test::More' => 0,
		   };
$hash{CONFIGURE_REQUIRES} = {
			     'PDL'=>0,
			     'ExtUtils::MakeMaker'=>0,
			    };
push(@{$hash{LIBS}}, '-lm');
$hash{DIR} = [];
#$hash{INC} .= ' -Isrc';
$hash{OBJECT} .= ' cluster.o';


WriteMakefile(%hash);

sub MY::postamble {
  pdlpp_postamble($package)
  .qq(

##-- readme
readme: README.txt

);
}

##-- avoid applying 'processPL' rules to 'Config.PL'
sub MY::processPL { return ''; }
