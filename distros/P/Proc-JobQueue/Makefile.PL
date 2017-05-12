
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Proc/JobQueue.pm',
	'NAME' => 'Proc-JobQueue',
	'ABSTRACT' => 'Jobqueue with dependency graph',
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	META_MERGE     => {
		resources  => {
			repository => 'http://github.com/muir/Proc-JobQueue',
		}
	},
	'PREREQ_PM'	=> {
		'File::Temp'			=> 0,
		'Tie::Function::Examples'	=> 0,
		'Scalar::Util'			=> 0,
		'Callback'			=> 0,
		'RPC::ToWorker'			=> 0.5,
		'Hash::Util'			=> 0,
		'Proc::Background'		=> 0,
		'File::Slurp::Remote'		=> 0.43,
		'Time::HiRes'			=> 0,
		'Hash::Util'			=> 0,
		'aliased'			=> 0,
		'Eval::LineNumbers'		=> 0,
		'File::Slurp'			=> 0,
		'Object::Dependency'		=> 0.32,
		'List::MoreUtils'		=> 0,
	},
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/Proc/JobQueue.pm
	pod2text lib/Proc/JobQueue.pm >README

END_OF_POSTAMBLE
}


