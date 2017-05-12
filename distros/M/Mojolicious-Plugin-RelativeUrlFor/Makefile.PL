use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Mojolicious::Plugin::RelativeUrlFor',
    AUTHOR          => 'Mirko Westermeier <mirko@westermeier.de>',
    VERSION_FROM    => 'lib/Mojolicious/Plugin/RelativeUrlFor.pm',
    PREREQ_PM       => {'Mojolicious' => '4.90'},
);
