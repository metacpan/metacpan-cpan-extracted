#! /usr/bin/perl -w
use 5.010;
use strict;

use ExtUtils::MakeMaker;

my $BUILD_REQUIRES = {
    'Test::Simple'     => 0.94,
    'Test::NoWarnings' => 0,
};

WriteMakefile(
    NAME          => 'MooX::Role::CryptedPassword',
    VERSION_FROM  => 'lib/MooX/Role/CryptedPassword.pm',
    ABSTRACT_FROM => 'lib/MooX/Role/CryptedPassword.pm',

    PREREQ_PM => {
        %$BUILD_REQUIRES,

        'autodie'         => 0,
        'Crypt::CBC'      => 0,
        'Crypt::Rijndael' => 0,
        'Moo'             => 2,
    },

    LICENSE  => 'perl_5',
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
