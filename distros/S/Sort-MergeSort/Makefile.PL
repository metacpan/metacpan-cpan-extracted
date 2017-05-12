
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Sort/MergeSort.pm',
	'NAME' => 'Sort-MergeSort',
	($] >= 5.005 ?
	('ABSTRACT' => 'Merge sorted streams to create a new stream',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM' => {
		'Test::NoWarnings'	=> 0,
	},
	'META_MERGE'     => {
		resources  => {
			repository => 'http://github.com/muir/Sort-MergeSort',
		},
	},
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/Sort/MergeSort.pm
\tpod2text lib/Sort/MergeSort.pm > README

END_OF_POSTAMBLE
}

