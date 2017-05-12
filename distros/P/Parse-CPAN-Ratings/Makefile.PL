#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Parse::CPAN::Ratings',
    VERSION_FROM => 'lib/Parse/CPAN/Ratings.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'Parse CPAN Ratings',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Moose'                      => '0',
        'MooseX::StrictConstructor'  => '0',
        'MooseX::Types::Path::Class' => '0',
        'Parse::CSV'                 => '0',
    }
);

