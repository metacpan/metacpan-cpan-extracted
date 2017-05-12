use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Speech::Swift::Simple',
	VERSION_FROM      => 'lib/Speech/Swift/Simple.pm',
	PREREQ_PM         => {
		'Speech::Swift'	=> 0,
	},
	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/Speech/Swift/Simple.pm',
       		AUTHOR         => 'Mike Pultz <mike@mikepultz.com>'
	) : ()),
);
