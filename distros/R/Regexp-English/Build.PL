use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::English',
    license             => 'perl',
    dist_author         => 'chromatic <chromatic@wgz.org>',
    dist_version_from   => 'lib/Regexp/English.pm',
	requires            =>
	{
		'Scalar::Util'  => '1.21',
	},
    build_requires      =>
	{
        'Test::Simple'  => '0.60',
    },
    add_to_cleanup      => [ 'Regexp-English-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
