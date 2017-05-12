use strict;
use Test::More;

use_ok('Net::Flotum');
ok( my $flotum = Net::Flotum->new( merchant_api_key => 'm-just-testing' ), 'new ok' );

my $rand = rand . rand . rand;
my $cus  = $flotum->new_customer(
    name           => 'cron',
    legal_document => '31737338602',
    remote_id      => $rand,
);
is( $cus->loaded, '0',    'object is not loaded' );
is( $cus->name,   'cron', 'name lazy loaded ok' );
is( $cus->loaded, '1',    'object is loaded' );

my $ret = $cus->update(
    bank_code                    => '237',
    bank_locator                 => '1234',
    bank_locator_verification    => 1,
    bank_account                 => '1223',
    bank_account_verification    => '1',
    bank_account_document_number => '00000000000',
    bank_account_legal_name      => 'foo bar zum',
    name                         => 'zumbi'

);
is( $ret->{id},   $cus->id, 'updated with success and id matches' );
is( $cus->loaded, '0',      'object is no longer loaded after update' );
is( $cus->name,   'zumbi',  'name update is reflected after update' );

my $cus2 = $flotum->load_customer( id => $cus->id, lazy => 1 );
is( $cus2->loaded,    '0',     'object is not loaded' );
is( $cus2->name,      'zumbi', 'name now is zumbi' );
is( $cus2->bank_code, '237',   'bank_code now exists' );
is( $cus2->loaded,    '1',     'after reading `name` object is loaded' );

my $cus3 = $flotum->load_customer( remote_id => $rand );
is( $cus3->loaded, '1',      'object is already loaded with `remote_id` is used' );
is( $cus3->id,     $cus->id, 'id is the same' );

done_testing;
