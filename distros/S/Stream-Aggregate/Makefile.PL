
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Stream/Aggregate.pm',
	'NAME' => 'Stream-Aggregate',
	($] >= 5.005 ?
	('ABSTRACT' => 'Aggregate a data stream',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM' => {
		'Hash::Util'	=> 0,
		'B::Deparse'	=> 0,
		'List::Util'	=> 0,
		'Config::Checker' 	=> 0,
		'List::EvenMoreUtils'	=> 0,
		'Config::YAMLMacros'	=> 0,
		'Data::Dumper'		=> 0,
		'List::MoreUtils'	=> 0,
		'Clone'		=> 0,
		'Tie::Function::Examples' => 0
	},
	'BUILD_REQUIRES' => {
		'YAML'		=> 0,
	},
	META_MERGE     => {
		resources  => {
			repository => 'http://github.com/muir/Stream-Aggregate',
		},
	},

);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/Stream/Aggregate.pod
	pod2text lib/Stream/Aggregate.pod >README

END_OF_POSTAMBLE
}

