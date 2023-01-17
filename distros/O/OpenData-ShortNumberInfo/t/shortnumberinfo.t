use v5.36;
use OpenData::ShortNumberInfo;
use Test::More;

diag '103 is EMS';
can_ok( OpenData::ShortNumberInfo -> new( number => 103 ), 'name' );
new_ok( 'OpenData::ShortNumberInfo', [ number => 103 ], 'Səhiyyə Nazirliyi' );
new_ok( 'OpenData::ShortNumberInfo', [ number => 0 ], 'Məlumat tapılmadı' );

done_testing;
