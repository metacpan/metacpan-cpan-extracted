use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Scope::OnExit',
    license             => 'perl',
    dist_author         => 'Leon Timmermans <leont@cpan.org>',
    dist_version_from   => 'lib/Scope/OnExit.pm',
	configure_requires  => {
		'Module::Build' => 0,
	},
	build_requires      => {
		'ExtUtils::CBuilder' => 0,
		'Module::Build' => 0,
		'Test::More'    => 0,
	},
	requires            => {
		perl            => 5.006000,
	},
	meta_merge => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scope-OnExit',
		},
		keywords        => [ 'scope', 'end' ],
	},
    add_to_cleanup      => [ 'Scope-OnExit-*' ],
	create_makefile_pl  => 'passthrough',
	sign                => 1,
);

$builder->create_build_script();
