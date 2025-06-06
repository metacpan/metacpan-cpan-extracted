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
		    'PDL' => '2.081',
		    'Test::More' => 0,
		   };
$hash{CONFIGURE_REQUIRES} = {
			     'PDL'=>'2.081',
			     'ExtUtils::MakeMaker'=>0,
			    };
push(@{$hash{LIBS}}, '-lm');
$hash{DIR} = [];
#$hash{INC} .= ' -Icluster-1.54';
$hash{OBJECT} .= ' ccluster.o';
##
$hash{META_MERGE} = {
		     "meta-spec" => { version => 2 },
		     resources => {
				   repository => {
						  type => 'git',
						  url => 'git://github.com/moocow-the-bovine/PDL-Cluster.git',
						  web => 'https://github.com/moocow-the-bovine/PDL-Cluster',
						 },
				  },
		    };


WriteMakefile(%hash);

sub MY::postamble {
  return q(

##-- readme
readme: README.txt

);
}

##-- avoid applying 'processPL' rules to 'Config.PL'
sub MY::processPL { return ''; }
