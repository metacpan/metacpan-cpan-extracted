use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME          => 'Mojolicious::Plugin::FormValidatorLazy',
    AUTHOR        => 'Sugama Keita <sugama@jamadam.com>',
    VERSION_FROM  => 'lib/Mojolicious/Plugin/FormValidatorLazy.pm',
    ABSTRACT_FROM => 'lib/Mojolicious/Plugin/FormValidatorLazy.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Mojolicious' => '6.38',
    },
    BUILD_REQUIRES => {
        'Test::More'            => '0.47',
        'Test::UseAllModules'   => '0.10',
    },
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                web  => 'https://github.com/jamadam/Mojolicious-Plugin-FormValidatorLazy',
                url  => 'https://github.com/jamadam/Mojolicious-Plugin-FormValidatorLazy.git',
            },
            bugtracker => {
                web  => 'https://github.com/jamadam/Mojolicious-Plugin-FormValidatorLazy/issues',
            },
        },
    },
    test => {TESTS => 't/*.t t/*/*.t'},
);

my $eumm = $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{MIN_PERL_VERSION} if $eumm < 6.48;
delete $params{META_MERGE}       if $eumm < 6.46;
delete $params{META_ADD}         if $eumm < 6.46;
delete $params{LICENSE}          if $eumm < 6.31;

if ($eumm < 6.52 && $params{CONFIGURE_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}          || {} },
        %{ $params{CONFIGURE_REQUIRES} },
    };
    delete $params{CONFIGURE_REQUIRES};
}
if ($eumm < 6.5503 && $params{BUILD_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}      || {} },
        %{ $params{BUILD_REQUIRES} },
    };
    delete $params{BUILD_REQUIRES};
}

WriteMakefile(%params);
