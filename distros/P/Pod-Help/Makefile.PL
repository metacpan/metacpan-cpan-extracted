use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'          => 'Pod::Help',
	'VERSION_FROM'  => 'lib/Pod/Help.pm', # finds $VERSION
	'PREREQ_PM'     => {
		'Test::More'    => 0,
		'Pod::Perldoc'  => 0,
#		'Pod::Readme'   => '0.05', # only needed for 'make dist'
	},
	($] >= 5.005 ? (   ## Add these new keywords supported since 5.005
		ABSTRACT_FROM   => 'lib/Pod/Help.pm', # retrieve abstract from module
		AUTHOR          => 'M. Jacob <jacob@j-e-b.net>') : (),
		LICENSE         => 'perl',
		depend          => {
			create_distdir  => 'Changes',
			Changes         => 'lib/Pod/Help.pm'."\n\t".q[$(FULLPERLRUN) -MPod::Readme -e 'Pod::Readme->new( readme_type => "changes" )->parse_from_file( "lib/Pod/Help.pm", "Changes" )']."\n\n",
		},
		realclean       => {
			FILES           => "Changes"
		},
	),
);
