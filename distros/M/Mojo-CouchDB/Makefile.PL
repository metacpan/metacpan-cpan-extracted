use 5.016;

use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojo::CouchDB',
    VERSION_FROM => 'lib/Mojo/CouchDB.pm',
    ABSTRACT     => 'CouchDB the Mojo way',
    AUTHOR       => 'Rawley Fowler <rawleyfowler@proton.me>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version   => 2},
        no_index       => {directory => ['examples', 't']},
        prereqs        => {runtime   => {requires => {perl => '5.020'}}},
        resources      => {
            bugtracker => {web => 'https://github.com/rawleyfowler/Mojo-CouchDB/issues'},
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository =>
                {type => 'git', url => 'https://github.com/rawleyfowler/Mojo-CouchDB'}
        },
    },
    PREREQ_PM => {'Test::Exception' => '0.43', 'Mojolicious' => '8.50', 'URI' => '5.19'},
    test      => {TESTS             => 't/*.t t/*/*.t'}
);
