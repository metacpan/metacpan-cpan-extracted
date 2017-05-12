use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT     => 'Mojolicious ♥ Mysql',
    NAME         => 'MojoX::Mysql',
    VERSION_FROM => 'lib/MojoX/Mysql.pm',
    AUTHOR       => 'Kostya Ten <kostya@cpan.org>',
    PREREQ_PM    => {'Mojolicious' => '6.11', 'DBD::mysql' => '4.028', 'DBI' => '1.631'},
    LICENSE      => 'apache',
    META_MERGE   => {
        requires  => {perl => '5.010001'},
        resources => {
            license    => 'http://opensource.org/licenses/Apache-2.0',
            bugtracker => 'https://github.com/MojoX/MojoX-Mysql/issues',
            repository => 'https://github.com/MojoX/MojoX-Mysql',
        },
        no_index => {directory => ['t']}
    },
    test         => {TESTS => 't/*.t'}
);
