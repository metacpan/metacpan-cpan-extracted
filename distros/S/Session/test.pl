use Test;

my %config =
(
    Store => 'File',
    Lock => 'Null',
    Generate => 'MD5',
    Serialize => 'Storable',
    Directory => '.',
);

plan test => 11;

use Session;
ok(1);

my $s = new Session undef, %config;
ok($s);

my $id = $s->session_id();
ok($id);

$s->set(test => 'test');
ok($s->get('test'), 'test');
ok($s->exists('test'));
ok($s->keys() == 1);
$s->release();

my $s2 = new Session $id, %config;
ok($s2);

ok($s2->get('test'), 'test');
ok($s2->remove('test'));
ok(!$s2->exists('test'));
$s2->delete();

my $s3 = new Session $id, %config;
ok(not defined $s3);

