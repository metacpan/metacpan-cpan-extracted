use strict;
use warnings;

use 5.005004;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Filter::HTTPD::Chunked',
    license             => 'perl',
    requires            => {
        'POE::Filter'       => '0',
        'HTTP::Request'     => '0',
        'HTTP::Response'    => '0',
    },
    create_makefile_pl  => 'passthrough',
    create_readme       => 1,
);

$builder->create_build_script;
