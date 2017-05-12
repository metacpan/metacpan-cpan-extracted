#!/usr/bin/perl
use utf8;
use SimpleDBI::mysql;
use Encode;
use Encode::Locale;

my $mysql = SimpleDBI::mysql->new(
    db     => 'testdb',
    host   => '127.0.0.1',
    usr    => 'someusr',
    passwd => 'somepwd',
);

my $data = $mysql->query_db('select * from sometable limit 2');
print encode( locale => $_ ), "\n" for @{ $data->[0] };

my $test_data = [ [qw/1 测试/], [qw/2 无聊/], ];
$mysql->load_table(
    $test_data,
    db      => 'otherdb',
    table   => 'testtable',
    fields  => [qw/id name/],
    charset => 'utf8',
);
