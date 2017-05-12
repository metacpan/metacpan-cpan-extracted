
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Proc/Parallel.pm',
	'NAME' => 'Proc-Parallel',
	'ABSTRACT' => 'Stream from multiple commands at once library and command',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'EXE_FILES' => [ 'bin/do.hosts', 'bin/rkill' ],
	META_MERGE     => {
		resources  => {
			repository => 'http://github.com/muir/Proc-Parallel',
		}
	},
	'PREREQ_PM'	=> {
		'IO::Event'			=> 0.704,
		'File::Slurp::Remote'		=> 0,
		'Scalar::Util'			=> 0,
		'IO::Handle'			=> 0,
		'List::Util'			=> 0,
		'Tie::Function::Examples'	=> 0,
		'Module::Load'			=> 0,
		'Eval::LineNumbers'		=> 0,
	},
);

