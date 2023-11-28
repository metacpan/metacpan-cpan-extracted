use strict;
use warnings;

use utf8;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::IsBot',
    VERSION_FROM => 'lib/Mojolicious/Plugin/IsBot.pm',
    ABSTRACT     =>
qq{A Mojolicious plugin that adds a helper to test if a request is a bot.},
    license    => 'artistic_2',
    META_MERGE => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => [ 'examples', 't' ] },
        prereqs        => { runtime   => { requires => { perl => '5.016' } } },
        resources      => {
            bugtracker => {
                web =>
'https://github.com/rawleyfowler/mojolicious-plugin-IsBot/issues'
            },
            license =>
              [qq{http://www.opensource.org/licenses/artistic-license-2.0}],
            repository => {
                type => 'git',
                url  =>
                  'https://github.com/rawleyfowler/mojolicious-plugin-IsBot'
            }
        },
    },
    TEST_REQUIRES => {
        'Test::Simple' => '1.302195'
    },
    PREREQ_PM => {
        'Mojolicious' => '9.00',
    },
    test => { TESTS => 't/*.t t/*/*.t it/*.t it/*/*.t' }
);
