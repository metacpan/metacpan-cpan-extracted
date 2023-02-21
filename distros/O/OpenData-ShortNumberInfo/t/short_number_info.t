use v5.37.9;
use feature 'class';

use OpenData::ShortNumberInfo;
use Test::More;

diag '103 is EMS';

can_ok( OpenData::ShortNumberInfo -> new( number => 103 ) , 'name' );
# If the "name" attribute works

new_ok( 'OpenData::ShortNumberInfo' , [ number => 103 ] , 'Səhiyyə Nazirliyi' );
# If the result (organization name) is correct for the number provided

new_ok( 'OpenData::ShortNumberInfo' , [ number => 0 ] , 'Məlumat tapılmadı' );
# If the return message is correct if the number is invalid

done_testing;
