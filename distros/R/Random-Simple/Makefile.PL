use v5.8.5;
use ExtUtils::MakeMaker 7.12; # for XSMULTI option

my %opts = (
	NAME             => 'Random::Simple',
	VERSION_FROM     => 'lib/Random/Simple.pm',
	ABSTRACT_FROM    => 'lib/Random/Simple.pm',
	XSMULTI          => 1,
	AUTHOR           => 'Scott Baker <bakerscot@cpan.org>',
	LICENSE          => 'mit',
	MIN_PERL_VERSION => '5.012',

	PREREQ_PM          => { 'ExtUtils::MakeMaker' => '7.12', },
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '7.12', },
	TEST_REQUIRES      => { 'Test::More' => '0', },

	META_MERGE => {
		dynamic_config => 1,
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				url => 'https://github.com/scottchiefbaker/perl-Random-Simple.git',
				web => 'https://github.com/scottchiefbaker/perl-Random-Simple',
				type => 'git'
			},
			bugtracker => {
				"web" => "https://github.com/scottchiefbaker/perl-Random-Simple/issues"
			},
		}
	},
);

# If you're on Windows you need the Win32 API also
if ($^O eq 'MSWin32') {
	$opts{'PREREQ_PM'}{'Win32::API'} = '0.79';
}

############################################################################

WriteMakefile(%opts);
