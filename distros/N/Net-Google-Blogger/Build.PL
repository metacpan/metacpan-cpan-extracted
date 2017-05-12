use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Google::Blogger',
    license             => 'perl',
    dist_author         => q{Egor Shipovalov <kogdaugodno@gmail.com>},
    dist_version_from   => 'lib/Net/Google/Blogger.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    requires => {
        'Any::Moose'            => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request::Common' => 0,
        'XML::Simple'           => 0,
    },
    add_to_cleanup      => [ 'Net-Google-Blogger-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
