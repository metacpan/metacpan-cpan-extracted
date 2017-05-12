#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::FleetDB',
    VERSION_FROM => 'lib/Net/FleetDB.pm',
    ABSTRACT     => 'Query FleetDB',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::Exception'            => '0',
        'Test::More'                 => '0',
        'JSON::XS::VersionOneAndTwo' => '0',
    }
);

