use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::YASA',
    license             => 'perl',
    dist_author         => 'Cheng-Lung Sung <clsung@FreeBSD.org>',
    dist_version_from   => 'lib/Net/YASA.pm',
    build_requires => {
	'Encode' => 0,
	'LWP::UserAgent' => 0
    },
    auto_features => {
        json_support => { 
            description => "Use JSON output",
            requires    => {'JSON::Any' => 0 }
        },
    },
    add_to_cleanup      => [ 'Net-YASA-*' ],
);

if ( $builder->feature('json_support') ) {
    $builder->notes( jsontests => 1 );
}
$builder->create_build_script();
