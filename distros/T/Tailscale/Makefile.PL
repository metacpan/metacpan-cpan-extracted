use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tailscale',
    VERSION_FROM     => 'lib/Tailscale.pm',
    ABSTRACT         => 'Perl bindings for tailscale-rs (Tailscale in Rust)',
    AUTHOR           => 'Brad Fitzpatrick <brad@danga.com>',
    LICENSE          => 'bsd',
    MIN_PERL_VERSION => '5.020',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'FFI::Platypus'        => '2.00',
        'FFI::CheckLib'        => 0,
        'HTTP::Request'        => 0,
        'HTTP::Response'       => 0,
        'HTTP::Status'         => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
        'JSON::PP'    => 0,
        'File::Temp'  => 0,
    },
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tailscale/tailscale-rs.git',
                web  => 'https://github.com/tailscale/tailscale-rs',
            },
            bugtracker => {
                web => 'https://github.com/tailscale/tailscale-rs/issues',
            },
        },
    },
    test => { TESTS => 't/*.t' },
);
