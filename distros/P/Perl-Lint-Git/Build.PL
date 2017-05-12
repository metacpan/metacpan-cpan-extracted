use 5.006;
use strict;
use warnings;
use Module::Build;


my $class = Module::Build->subclass(
	code =>
	q|
		# Override 'test' to support running extended tests in the xt/
		# directory.
		sub ACTION_test
		{
			my ( $self ) = @_;

			$self->recursive_test_files(1);

			$self->test_files( 't', 'xt' )
				if $ENV{'RELEASE_TESTING'};

			return $self->SUPER::ACTION_test();
		}

		# Force running extended tests when testing the distribution.
		sub ACTION_disttest
		{
			my ( $self ) = @_;

			local $ENV{ RELEASE_TESTING } = 1;

			return $self->SUPER::ACTION_disttest();
		}
	|,
);

my $builder = $class->new(
	module_name         => 'Perl::Lint::Git',
	license             => 'Perl_5',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/Perl/Lint/Git.pm',
	build_requires      =>
	{
		'File::Path'                     => 0,
		'Git::Repository'                => 0,
		'Test::Deep'                     => 0,
		'Test::Exception'                => 0,
		'Test::FailWarnings'             => 0,
		'Test::Git'                      => 0,
		'Test::Requires::Git'            => 1.005,
		'Test::More'                     => 0,
	},
	requires            =>
	{
		'perl'                           => 5.006,
		'Carp'                           => 0,
		'Data::Dumper'                   => 0,
		'File::Basename'                 => 0,
		'Git::Repository'                => 0,
		'Git::Repository::Plugin::Blame' => 0,
		'Perl::Lint'                     => 0.21,
	},
	add_to_cleanup      =>
	[
		'Perl-Lint-Git-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build'                  => 0,
	},
	meta_merge          =>
	{
		resources                        =>
		{
			repository  => 'https://github.com/guillaumeaubert/Perl-Lint-Git',
			homepage    => 'https://metacpan.org/release/Perl-Lint-Git',
			bugtracker  => 'https://github.com/guillaumeaubert/Perl-Lint-Git/issues',
		},
	},
);

$builder->create_build_script();
