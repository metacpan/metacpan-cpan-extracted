#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::Cassandra',
    VERSION_FROM => 'lib/Net/Cassandra.pm',
    ABSTRACT     => 'Interface to Cassandra',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Moose'                     => '0',
        'MooseX::StrictConstructor' => '0',
    }
);

