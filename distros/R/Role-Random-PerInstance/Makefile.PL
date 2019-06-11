use strict;
use warnings;
require 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'Role::Random::PerInstance',
    'AUTHOR'        => q{Curtis 'Ovid' Poe <ovid@cpan.org>},
    'VERSION_FROM'  => 'lib/Role/Random/PerInstance.pm',
    'ABSTRACT_FROM' => 'lib/Role/Random/PerInstance.pm',
    'LICENSE'       => 'artistic_2',
    'PREREQ_PM'     => {
        'List::Util'  => '1.4',
        'Math::Round' => '0.07',
        'Moose::Role' => 0,
        'Test::Most'  => '0.35',
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    META_MERGE    => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:Ovid/role-random-perinstance.git',
                web  => 'https://github.com/Ovid/role-random-perinstance.git',
            },
        },
    },
);
