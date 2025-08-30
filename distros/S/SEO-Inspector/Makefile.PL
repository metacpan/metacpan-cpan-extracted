use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'SEO::Inspector',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/SEO/Inspector.pm',
	ABSTRACT_FROM	=> 'lib/SEO/Inspector.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM => {
		'Carp' => 0,
		'Getopt::Long' => 0,
		'File::Slurp' => 0,
		'IPC::System::Simple' => 0,
		'Mojo::UserAgent' => 0,
		'Mojo::URL' => 0,
		'Module::Pluggable' => 0,
		'HTML::TreeBuilder' => 0,
	}, TEST_REQUIRES => {
		'File::Path' => 0,
		'File::Spec' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'FindBin' => 0,
		'IPC::Run3' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'SEO-Inspector-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/SEO::Inspector',
			repository => {
				repository => 'https://github.com/nigelhorne/SEO-Inspector',
				type => 'git',
				url => 'git://github.com/nigelhorne/SEO-Inspector.git',
				web => 'https://github.com/nigelhorne/SEO-Inspector',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-SEO-Inspector@rt.cpan.org',
				url => 'https://github.com/nigelhorne/SEO-Inspector/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=SEO-Inspector',
				web => 'https://github.com/nigelhorne/SEO-Inspector/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
