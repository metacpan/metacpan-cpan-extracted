
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/proc-simple-perl',
        },
    }
};

WriteMakefile( 
        'VERSION_FROM' => "Simple.pm",
	'NAME'	  => 'Proc::Simple',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	PREREQ_PM => {
	    'Test::More' => 0,
	    'IO::Handle' => 0,
	},
        $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
);
