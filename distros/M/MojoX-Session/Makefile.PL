#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME          => 'MojoX::Session',
    VERSION_FROM  => 'lib/MojoX/Session.pm',
    ABSTRACT_FROM => 'lib/MojoX/Session.pm',
    AUTHOR        => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/mojox-session'
                },
                no_index => {directory => [qw/t/]}
            }
        )
    ),

    PREREQ_PM => {
        'Digest::SHA'  => 0,
        'MIME::Base64' => 0,
        'Mojolicious'  => '4',
        'Storable'     => 0,
        'Test::More'   => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'MojoX-Session-*'},
    test  => {TESTS    => 't/*.t t/*/*.t'}
);
