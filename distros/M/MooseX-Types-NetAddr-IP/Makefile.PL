
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MooseX::Types::NetAddr::IP',
    AUTHOR        => 'Todd Caine <todd.caine@gmail.com>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/MooseX/Types/NetAddr/IP.pm',
    ABSTRACT_FROM => 'lib/MooseX/Types/NetAddr/IP.pm',
    INSTALLDIRS   => 'site',
    PREREQ_PM     => {
        'Moose'                 => '0.41',
        'MooseX::Types'         => '0.19',
        'namespace::clean'      => '0.08',
        'NetAddr::IP'           => 0,
        'Test::Exception'       => 0,
        'Module::Runtime'       => '0.014',
    },
);

