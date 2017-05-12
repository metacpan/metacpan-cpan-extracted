use 5.006;
use strict;
use warnings;
use Module::Build 0.25;

my $builder = Module::Build->new(
	module_name         => 'Scalar::Induce',
	license             => 'perl',
	dist_author         => 'Leon Timmermans <leont@cpan.org>',
	dist_version_from   => 'lib/Scalar/Induce.pm',
	  'build_requires' => {
    'B' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.4005',
    'Test::Differences' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.4005'
  },
  'requires' => {
    'Carp' => '0',
    'Exporter' => '5.57',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
	meta_merge => {
		resources       => {
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Induce',
		},
		keywords        => [ qw/induce reduce/ ],
	},
	add_to_cleanup      => [ 'Scalar-Induce-*' ],
	allow_pureperl      => 1,
);

$builder->create_build_script();
