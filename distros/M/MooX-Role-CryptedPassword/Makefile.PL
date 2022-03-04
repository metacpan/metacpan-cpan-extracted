#! /usr/bin/perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker 6.55_03;

my $BUILD_REQUIRES = {
    'Test::Simple'   => 0.94,
    'Test::Warnings' => 0,
    'Test::Fatal'    => 0,
};

WriteMakefile(
    NAME          => 'MooX::Role::CryptedPassword',
    VERSION_FROM  => 'lib/MooX/Role/CryptedPassword.pm',
    ABSTRACT_FROM => 'lib/MooX/Role/CryptedPassword.pm',

    BUILD_REQUIRES => $BUILD_REQUIRES,
    PREREQ_PM      => {
        %$BUILD_REQUIRES,

        'autodie'         => 0,
        'Crypt::CBC'      => 2.35, # PBKDF2 support
        'Crypt::Rijndael' => 0,
        'Moo'             => 2,
    },

    LICENSE  => 'perl',
    MIN_PERL_VERSION => '5.010001',
    META_ADD => {
        'meta-spec' => {version => 2},
        'resources' => {
            homepage   => '',
            repository => {
                type => 'git',
                url  => 'git@github.com:abeltje/MooX-Role-CryptedPassword.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
