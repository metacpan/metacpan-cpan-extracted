# Makefile.PL for Mojolicious::Plugin::Sprite.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# Copyright 2013 Yuriy Ustushenko, all rights reserved.

use 5.008008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Sprite',
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Sprite.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Sprite.pm',
    AUTHOR           => 'Yuriy Ustushenko <yoreek@yahoo.com>',
    LICENSE          => "perl",
    MIN_PERL_VERSION => 5.008008,
    PREREQ_PM    => {
        'Mojolicious' => '2.68',
        'XML::LibXML' => 0,
    },
    test             => {TESTS => 't/*.t'}
);
