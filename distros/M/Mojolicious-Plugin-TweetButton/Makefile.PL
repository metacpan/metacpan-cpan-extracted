#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::TweetButton',
    VERSION_FROM => 'lib/Mojolicious/Plugin/TweetButton.pm',
    ABSTRACT     => 'TweetButton plugin for Mojolicious',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    repository =>
                      'http://github.com/vti/mojolicious-plugin-tweet_button'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {'Mojo' => '0.999926',},
    test      => {TESTS  => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);
