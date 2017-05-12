#!perl
use strict;
use warnings;

use FindBin;
use Test::Most tests => 16;

BEGIN {
    use_ok( 'TV::Humax::Foxsat::hmt_data' ) || print "Bail out!\n";
}

my $test_data_file = $FindBin::Bin."/test_files/Downton_Abbey_20121007_2159.hmt";

note('setup');

ok( -f $test_data_file, 'Test data present');

my $hmt_data = new TV::Humax::Foxsat::hmt_data();
$hmt_data->raw_from_file($test_data_file);

is( $hmt_data->EPG_Block_count, 2, 'File has 2 EPG Blocks'  );

my $epg_blocks;
lives_ok(
    sub{ $epg_blocks = $hmt_data->EPG_blocks() },
    'Can extract the epg blocks'
);
my ($epg_block1, $epg_block2) = @$epg_blocks;

note('First block unpacked');
{
    is_deeply(
        $epg_block1->startTime, 
        DateTime->from_epoch( epoch => 1349643600, time_zone => 'GMT' ),
        'startTime'
    );
    is( $epg_block1->duration, 3600, 'duration' );
    is( $epg_block1->progName,  'The X Factor Results', 'progName'  );
    is(
        $epg_block1->guideInfo,
         'Dermot O\'Leary presents the results of the first public vote. Featuring superstar performances from chart-topping R&B singer Ne-Yo and former X Factor winner Leona Lewis. [S]',
         'guideInfo'
    );
    is( $epg_block1->guideFlag,  '', 'guideFlag'  );
    is( $epg_block1->guideBlockLen,  140, 'guideBlockLen'  );
}

note('Second block unpacked');
{
    is_deeply(
        $epg_block2->startTime, 
        DateTime->from_epoch( epoch => 1349647200, time_zone => 'GMT' ),
        'startTime'
    );
    is( $epg_block2->duration, 3900, 'duration' );
    is( $epg_block2->progName,  'Downton Abbey', 'progName'  );
    is(
        $epg_block2->guideInfo,
         'Branson\'s political views land him in hot water and Sybil\'s loyalty is tested to the limit. Ethel is torn between head and heart as she makes a decision about her son\'s future. [AD,S]',
         'guideInfo'
    );
    is( $epg_block2->guideFlag,  '', 'guideFlag'  );
    is( $epg_block2->guideBlockLen,  184, 'guideBlockLen'  );
}

done_testing;
