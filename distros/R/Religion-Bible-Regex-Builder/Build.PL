use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Religion::Bible::Regex::Builder',
    license             => 'perl',
    dist_author         => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    dist_version_from   => 'lib/Religion/Bible/Regex/Builder.pm',
    requires => {
	'Religion::Bible::Regex::Config' => 0.5,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Religion-Bible-Regex-Builder-*' ],
);

$builder->create_build_script();
