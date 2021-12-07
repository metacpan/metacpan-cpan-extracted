package main;

use 5.020;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name         => 'MojoX::HTTP::Async',
    license             => 'Artistic',
    create_readme       => 1,
    configure_requires  => {
        'Module::Build' => '0.4220'
    },
    build_requires => {
        'Test::SharedFork' => 0.35,
        'Test::TCP' => 2.19,
        'Test::More' => 1.302183,
        'FindBin' => 1.51,
        'Net::EmptyPort' => 0,
    },
    requires => {
        'perl'  => 5.020,
        'POSIX' => 1.76,
        'Time::HiRes' => 1.9741,
        'Socket' => 2.030,
        'IO::Socket::SSL' => 2.072,
        'Fcntl' => 1.13,
        'Carp' => 1.42,
        'List::Util' => 1.4602,
        'Mojolicious' => 7.59,
        'Mojo::Message::Request' => 0,
        'Mojo::Message::Response' => 0,
        'Mojo::Transaction::HTTP' => 0,
        'URI' => 1.73,
        'Errno' => 1.28,
        'Scalar::Util' => 1.4602,
    },
    needs_compiler => 0,
    meta_merge     => {
        'resources' => {
            'bugtracker' => 'https://github.com/KalessinD/perl_mojox_http_async/issues',
            'repository' => 'https://github.com/KalessinD/perl_mojox_http_async',
        },
    }
);

$build->create_build_script;

1;
__END__
