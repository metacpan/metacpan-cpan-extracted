use 5.016;
use ExtUtils::MakeMaker;

my %opts = (
	NAME               => 'Perl::Minify',
	VERSION_FROM       => 'lib/Perl/Minify.pm',
	ABSTRACT_FROM      => 'lib/Perl/Minify.pm',
	AUTHOR             => 'Scott Baker <scott@perturb.org>',
	LICENSE            => 'perl',
	MIN_PERL_VERSION   => '5.016',
	EXE_FILES          => [ 'minify.pl' ],
	PREREQ_PM          => {
		'PPI'            => '0',
		'Getopt::Long'   => '0',
		'Scalar::Util'   => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
		'File::Temp' => '0',
	},

	META_MERGE => {
		dynamic_config => 1,
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				url => 'https://github.com/scottchiefbaker/perl-Perl-Minify.git',
				web => 'https://github.com/scottchiefbaker/perl-Perl-Minify',
				type => 'git'
			},
			bugtracker => {
				"web" => "https://github.com/scottchiefbaker/perl-Perl-Minify/issues"
			},
		}
	},
);

############################################################################

WriteMakefile(%opts);
