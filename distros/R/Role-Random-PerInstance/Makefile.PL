use strict;
use warnings;
require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Role::Random::PerInstance',
    'VERSION_FROM' => 'lib/Role/Random/PerInstance.pm',
    'PREREQ_PM'    => {
        'Test::Most'  => '0.35',
        'Math::Round' => '0.07',
        'List::Util'  => '1.4',
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
