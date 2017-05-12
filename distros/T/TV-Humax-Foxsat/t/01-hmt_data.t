#!perl
use strict;
use warnings;

use FindBin;
use Test::Most tests => 27;

BEGIN {
    use_ok( 'TV::Humax::Foxsat::hmt_data' ) || print "Bail out!\n";
}

my $test_data_file = $FindBin::Bin."/test_files/Downton_Abbey_20121007_2159.hmt";

note('Basic tests');

ok( -f $test_data_file, 'Test data present');

my $hmt_data;
lives_ok(
    sub{ $hmt_data = new TV::Humax::Foxsat::hmt_data() },
    'Can create an instance of hmt_dat'
);

isa_ok($hmt_data, 'TV::Humax::Foxsat::hmt_data');

dies_ok(
    sub{ $hmt_data->startTime() },
    'Dies if rawDataBlock is not defined'
);

lives_ok(
    sub{ $hmt_data->raw_from_file($test_data_file) },
    'Can populate with some raw data'
);

note('Unpacked data fields');

is( $hmt_data->lastPlay, 1006, 'lastPlay' );
is( $hmt_data->ChanNum,  112, 'ChanNum'  );

is_deeply(
    $hmt_data->startTime, 
    DateTime->from_epoch( epoch => 1349647192, time_zone => 'GMT' ),
    'startTime'
);

is_deeply(
    $hmt_data->endTime, 
    DateTime->from_epoch( epoch => 1349651100, time_zone => 'GMT' ),
    'endTime'
);

is( $hmt_data->progName,   'Downton Abbey', 'progName'  );
is( $hmt_data->ChanNameEPG,      'ITV1+1',  'ChanNameEPG'  );
is( $hmt_data->Freesat,          1,         'Freesat'  );
is( $hmt_data->Viewed,           '',        'Viewed'  );
is( $hmt_data->Locked,           '',        'Locked'  );
is( $hmt_data->HiDef,            '',        'HiDef'  );
is( $hmt_data->Encrypted,        '',        'Encrypted'  );
is( $hmt_data->CopyProtect,      '',        'CopyProtect'  );
is( $hmt_data->Locked,           '',        'Locked'  );
is( $hmt_data->AudioType,        'MPEG1',   'AudioType'  );
is( $hmt_data->VideoPID,         2383,     'VideoPID'  );
is( $hmt_data->AudioPID,         2384,     'AudioPID'  );
is( $hmt_data->TeletextPID,      2385,     'TeletextPID'  );
is( $hmt_data->VideoType,        'SD',      'VideoType'  );
is( $hmt_data->EPG_Block_count,  2,         'EPG_Block_count'  );

TODO: {
    local $TODO = 'fileName not working';
    is( $hmt_data->fileName,  '/media/sda1/Downton Abbey_20121007_2159', 'fileName'  );
};

TODO: {
    local $TODO = 'Subtitles gives the wrong answer';
    is( $hmt_data->Subtitles, 1, 'Subtitles'  );     # Probably wrong.
};

done_testing;
