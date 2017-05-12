use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Net::DAAP::DMAP',
    'VERSION_FROM' => 'lib/Net/DAAP/DMAP.pm',
    'PREREQ_PM'    => {
        'Math::Bigint' => 0,
        'Test::More'   => 0,
    },
);
