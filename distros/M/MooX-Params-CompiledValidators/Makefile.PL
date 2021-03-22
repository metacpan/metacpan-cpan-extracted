#! perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker '6.55_02';

WriteMakefile(
    NAME          => 'MooX::Params::CompiledValidators',
    VERSION_FROM  => 'lib/MooX/Params/CompiledValidators.pm',
    ABSTRACT_FROM => 'lib/MooX/Params/CompiledValidators.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    PREREQ_PM => {
        'Moo'                        => '2.003',
        'Params::ValidationCompiler' => '0.27',
        'Sub::Util'                  => '1.50',
        'Types::Standard'            => '1.008',
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_02',
    },

    BUILD_REQUIRES => {
        'Test::Fatal'      => '0.01',
        'Test::More'       => '0.88',    # done_testing()
        'Test::Warnings'   => '0.028',
    },

    MIN_PERL_VERSION => '5.010001',

    META_ADD => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
#            homepage  => "https://github.com/abeltje/MooX-Params-CompiledValidators",
            repository => {
                type   => "git",
#                url    => "git://github.com/abeltje/Passphrase-Generator.git",
                web    => "https://source.test-smoke.org/gitweb/?p=MooX-Params-CompiledValidators",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);
