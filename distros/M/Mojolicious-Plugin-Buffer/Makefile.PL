use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my %prereq_pm = (
	'autodie' => 0,
	'Carp' => 0,
	'Exporter' => 0,
	'Fcntl' => 0,
	'File::Path' => '2.07',	# 2.07 for make_path() and its error option
	'File::Spec' => 0,
	'IPC::System::Simple' => 0,	# needed by use autodie qw(:all)
	'Mojolicious' => '9.00',
	'Params::Get' => '0.17',
	'Params::Validate::Strict' => '0.41',
	'Readonly' => '2.00',
	'Return::Set' => '0.05',
	'Scalar::Util' => 0,
	'Sub::Private' => '0.07',	# 0.07 for per-package enforce mode
	'Sub::Protected' => '0.03',
	'Time::HiRes' => 0,
	'version' => 0,
);

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz',
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	=> 'Mojolicious::Plugin::Buffer',
	AUTHOR	=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM		=> 'lib/Mojolicious/Plugin/Buffer.pm',
	ABSTRACT_FROM		=> 'lib/Mojolicious/Plugin/Buffer.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
			? ('LICENSE'=> 'gpl_2')	# the POD says GPL 2 or later
			: ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Config' => 0,
		'Digest::MD5' => 0,
		'Encode' => 0,
		'Errno' => 0,
		'File::Basename' => 0,
		'File::Find' => 0,
		'File::Temp' => 0,
		'IO::Handle' => 0,
		'IO::Socket::INET' => 0,
		'POSIX' => 0,
		'Storable' => 0,
		'Test::More' => 0,
	},
	PREREQ_PM => \%prereq_pm,
	clean => { FILES => 'Mojolicious-Plugin-Buffer-*' },
	dist => $dist,
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		# The example applications declare packages such as MyApp; keep
		# PAUSE from indexing them
		no_index => {
			directory => [qw(examples benchmarks)],	# t and inc are added by EUMM
		},
		prereqs => {
			runtime => {
				recommends => {
					# Optional, checked for at runtime
					'CHI' => 0,
					'HTML::Packer' => 0,
					'IO::Compress::Brotli' => 0,
					'Compress::Zstd' => 0,
					# Either client makes Lock::Redis usable
					'Redis' => 0,
					'Redis::Fast' => 0,
				},
			},
			test => {
				recommends => {
					# t/locales.t resolves client addresses with it when present
					'IP::Country::Fast' => 0,
					# t/76-live-redis.t needs one of them and a server
					'Redis' => 0,
					'Redis::Fast' => 0,
					# t/90-without-recommended.t skips without it
					'Test::Without::Module' => 0,
					# t/pod.t and t/pod-coverage.t skip without them
					'Test::Pod' => '1.22',
					'Test::Pod::Coverage' => '1.08',
				},
			},
			develop => {
				requires => {
					# t/pod.t and t/pod-coverage.t skip without these
					'Test::Pod' => '1.22',
					'Test::Pod::Coverage' => '1.08',
				},
				recommends => {
					# t/schemas.t runs its extract-schemas script
					'App::Test::Generator' => 0,
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Mojolicious-Plugin-Buffer.git',
				web => 'https://github.com/nigelhorne/Mojolicious-Plugin-Buffer',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/Mojolicious-Plugin-Buffer/issues',
				url => 'https://github.com/nigelhorne/Mojolicious-Plugin-Buffer/issues',
				mailto => 'bug-Mojolicious-Plugin-Buffer@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.26.0',	# Params::Validate::Strict needs 5.26
);
