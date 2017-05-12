use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;

my $name = File::Temp::tmpnam;

my $db = RocksDB->new($name, { create_if_missing => 1 });
$db->put(foo => 'bar');
$db->update(sub {
    my $batch = shift;
    isa_ok $batch, 'RocksDB::WriteBatch';
    $batch->put(bar => 'baz');
    $batch->delete('foo');
    $batch->put_log_data(time);
});

is $db->get('bar'), 'baz';
is $db->get('foo'), undef;

my $batch = RocksDB::WriteBatch->new;
isa_ok $batch, 'RocksDB::WriteBatch';
$batch->put(hoge => 'fuga');
$batch->clear();
$batch->put(fuga => 'piyo');
$db->write($batch);
is $db->get('hoge'), undef;
is $db->get('fuga'), 'piyo';

done_testing;

END {
    RocksDB->destroy_db($name);
}
