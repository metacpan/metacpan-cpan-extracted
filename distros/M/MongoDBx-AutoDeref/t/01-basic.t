use Test::More;
use warnings;
use strict;
use Try::Tiny;
use MongoDB;
use MongoDBx::AutoDeref;
use Digest::SHA1('sha1_hex');

my $db_name = sha1_hex(time().rand().'mtfnpy'.$$);

my $skip = 0;

try
{
    MongoDB::Connection->new(host => ($ENV{MONGD} || 'localhost'));
}
catch
{
    $skip = 1;
};

if($skip)
{
    plan(skip_all => 'Unable to setup mongo for testing');
}

my $con = MongoDB::Connection->new(host => ($ENV{MONGD} || 'localhost'));
my $db = $con->get_database($db_name);
$db->drop();
my $col1 = $db->get_collection('bar');
my $col2 = $db->get_collection('foo');
my $doc1 = { foo => 'bar' };
my $doc2 = { bar => 'baz' };
my $doc3 = { baz => 'foo', 'hap', => 'boof' };

my $id1 = $col1->insert($doc1);
$doc2->{source} = { '$db' => $db_name, '$ref' => 'bar', '$id' => $id1 };
my $id2 = $col2->insert($doc2);
$doc3->{source} = { '$db' => $db_name, '$ref' => 'foo', '$id' => $id2 };
my $id3 = $col2->insert($doc3);
$doc1->{source} = { '$db' => $db_name, '$ref' => 'foo', '$id' => $id3 };
$col1->update({ _id => $id1}, $doc1);

my $fetch = $col2->find_one({_id => $id3});

is($fetch->{baz}, 'foo', 'doc3 element matches');
$fetch->{baz} = '123';
$col2->update({_id => $id3}, $fetch);
$fetch = $col2->find_one({_id => $id3});
is($fetch->{source}->fetch->{bar}, 'baz', 'doc2 element matches');
my $fetch2 = $fetch->{source}->fetch;
$fetch2->{bar} = '321';
$col2->update({_id => $id2}, $fetch2);
$fetch = $col2->find_one({_id => $id3});
is($fetch->{source}->fetch->{bar}, '321', 'doc2 element matches again after update');
is($fetch->{source}->fetch->{source}->fetch->{foo}, 'bar', 'doc1 element matches');
my $loop = $fetch->{source}
    ->fetch->{source}
    ->fetch->{source}
    ->fetch({hap => 1});
ok(exists($loop->{hap}) && !exists($loop->{baz}), 'loop and limit fetched');
is($loop->{hap}, 'boof',
    'loop through the circular structure and limit what is fetched');

$db->drop();
done_testing();
