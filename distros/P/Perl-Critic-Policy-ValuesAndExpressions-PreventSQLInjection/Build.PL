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
	module_name          => 'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/Perl/Critic/Policy/ValuesAndExpressions/PreventSQLInjection.pm',
	build_requires       =>
	{
		'Test::Deep'                    => 0,
		'Test::FailWarnings'            => 0,
		'Test::More'                    => 0,
		'Test::Perl::Critic::Policy'    => 0,
	},
	requires             =>
	{
		'perl'                          => 5.006,
		'Carp'                          => 0,
		'Perl::Critic::Policy'          => 0,
		'Perl::Critic::Utils'           => 0,
		'Readonly'                      => 0,
		'Try::Tiny'                     => 0,
		'String::InterpolatedVariables' => 0,
	},
	add_to_cleanup       =>
	[
		'Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection-*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'        => 0,
	},
	meta_merge           =>
	{
		resources              =>
		{
			repository  => 'https://github.com/guillaumeaubert/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection',
			homepage    => 'https://metacpan.org/release/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection',
			bugtracker  => 'https://github.com/guillaumeaubert/Perl-Critic-Policy-ValuesAndExpressions-PreventSQLInjection/issues',
		},
	},
);

$builder->create_build_script();
