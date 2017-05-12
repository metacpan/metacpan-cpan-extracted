use strict;
use warnings;

use ExtUtils::MakeMaker;
my %conf = (
	NAME         => "Test::CircularDependencies",
	AUTHOR       => 'Gabor Szabo <szabgab@cpan.org>',
	VERSION_FROM => 'lib/Test/CircularDependencies.pm',
	ABSTRACT_FROM => 'lib/Test/CircularDependencies.pm',
	PREREQ_PM    => {
		'Test::Builder'       => 0.01,
		'Carp'                => 0,
		'Data::Dumper'        => 0,
		'Exporter'            => 0,
		'Module::CoreList'    => 0,
		'Module::Path'        => 0,
		'Perl::PrereqScanner' => 0,
	},
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type       => 'git',
				url        => 'http://github.com/szabgab/Test-CircularDependencies.git',
				web        => 'http://github.com/szabgab/Test-CircularDependencies',
				license    => 'http://dev.perl.org/licenses/',
			},
			bugtracker => {
				web => 'http://github.com/szabgab/Test-CircularDependencies',
			},
		},
		x_contributors => [
			'Gabor Szabo <szabgab@cpan.org>',
		],
	};
}

my %configure_requires = (
	'ExtUtils::MakeMaker' => '6.64',
);
my %build_requires = ();
my %test_requires = (
	'Test::More'      => '1.00',

	'File::Temp' => '0.01',
);

###   merging data "standard code"
if (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
	$conf{CONFIGURE_REQUIRES} = \%configure_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %configure_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
	$conf{BUILD_REQUIRES} = \%build_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %build_requires);
}
if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}


WriteMakefile(%conf);

