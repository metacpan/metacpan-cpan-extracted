use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Steemit::WsClient',
    license             => 'artistic_2',
    dist_author         => q{snkoehn <snkoehn@cpan.com>},
    dist_version_from   => 'lib/Steemit/WsClient.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'        => '0',
        'Math::BigInt::GMP' => '1.6',
        'Math::BigInt'      => '1.999810',
    },
    requires => {
        'Math::BigInt::GMP' => '1.6',
        'Math::BigInt'      => '1.999810',
        'Modern::Perl'     => '0',
        'Mojo::Base'       => '0',
        'IO::Socket::SSL'  => '0',
        'Digest::SHA'      => '0',
        'Date::Calc'       => '0',
        'Math::EllipticCurve::Prime'  => '0',
        'Crypt::RIPEMD160' => '0',
    },
    recommends => {
    },
    add_to_cleanup     => [ 'Steemit-*' ],
);

$builder->create_build_script();
