use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Rexster::Client',
    license             => 'perl',
    dist_author         => 'Shohei Kameda <shoheik@cpan.org>',
    dist_version_from   => 'lib/Net/Rexster/Client.pm',
    requires => {
        'Test::More'    => 0,
        'Test::MockObject'    => 0,
        'Test::MockObject::Extends'    => 0,
        'Test::Perl::Critic'       => 0,
        'Test::Fake::HTTPD'    => 0,
        'version'       => 0,
        'Moose'         => 0,
        'Encode'        => 0,
        'Carp'        => 0,
        'LWP::UserAgent'    => 0,
        'JSON'          => 0,
        'URI::Escape'   => 0,
        'utf8'   => 0,
    },
    add_to_cleanup      => [ 'Net-Rexster-Client-*' ],
);

$builder->create_build_script();
