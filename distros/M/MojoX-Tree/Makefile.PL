use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT     => 'Mojolicious ♥ Tree',
    NAME         => 'MojoX::Tree',
    VERSION_FROM => 'lib/MojoX/Tree.pm',
    AUTHOR       => 'Kostya Ten <kostya@cpan.org>',
    PREREQ_PM    => {'Mojolicious' => '6.10', 'MojoX::Mysql' => '0.12'},
    LICENSE      => 'apache',
    META_MERGE   => {
        requires  => {perl => '5.010001'},
        resources => {
            license    => 'http://opensource.org/licenses/Apache-2.0',
            bugtracker => 'https://github.com/MojoX/MojoX-Tree/issues',
            repository => 'https://github.com/MojoX/MojoX-Tree',
        },
        no_index => {directory => ['t']}
    },
    test         => {TESTS => 't/*.t'}
);

