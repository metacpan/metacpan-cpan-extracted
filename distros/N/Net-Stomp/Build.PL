#!perl
use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Net::Stomp',
    requires           => {
        'IO::Socket::INET'      => '0',
        'IO::Select'            => '0',
        'Class::Accessor::Fast' => '0',
        'Log::Any'              => '1.707',
    },
    test_requires      => {
        'Test::More'             => '0',
        'Test::Deep'             => '0',
        'Test::Fatal'            => '0',
        'Log::Any::Adapter::TAP' => '0.003003',
        'Test::NiceDump'         => '1.0.0',
    },
    recommends         => {
        'IO::Socket::IP'        => '0.20',
        'IO::Socket::SSL'       => '1.75',
    },
);
$build->create_build_script;
