use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Mojolicious::Plugin::Subdispatch',
    VERSION_FROM    => 'lib/Mojolicious/Plugin/Subdispatch.pm',
    AUTHOR          => 'Mirko Westermeier <mail@memowe.de>',
    PREREQ_PM       => {'Mojolicious' => '4.0'},
    test            => {TESTS => 't/*.t'}
);
