use strict;
use warnings;
use utf8;
use Test::More;
use Net::Groonga::HTTP;
use Scalar::Util qw(looks_like_number);
use Data::Dumper;
use t::Groonga;

my $server = t::Groonga->start;
my $client = $server->client;

subtest 'call' => sub {
    my $response = $client->call('status');
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    ok(exists $response->result->{version});
};

subtest 'status' => sub {
    my $response = $client->status();
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    ok(looks_like_number($response->return_code));
    ok(looks_like_number($response->start_time));
    ok(looks_like_number($response->elapsed_time));
    is(ref($response->result), 'HASH');
    ok(exists $response->result->{version});
    diag "Groonga: " . $response->result->{version};
    note Dumper($response->data);
};

subtest 'table_create' => sub {
    my $response = $client->table_create(
        name => 'Foo',
        key_type => 'UInt64',
    );
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    ok($response->result);
    note Dumper($response->data);
};

subtest 'column_create' => sub {
    my $response = $client->column_create(
        table => 'Foo',
        name => 'bar',
        type => 'ShortText',
    );
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    ok($response->result);
    note Dumper($response->data);
};

subtest 'load' => sub {
    my $response = $client->load(
        table => 'Foo',
        values => [
            map {
                +{
                    _key => $_,
                    bar => "heh$_"
                },
            } 1..10
        ],
    );
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    note Dumper($response->data);
};

subtest 'select' => sub {
    subtest 'page 1' => sub {
        my $response = $client->select(
            table => 'Foo',
            limit => 3,
            offset => 0,
        );
        isa_ok($response, 'Net::Groonga::HTTP::Response');
        my $pager = $response->pager;
        isa_ok($pager, 'Net::Groonga::Pager');
        ok($response->is_success);
        ok($pager->has_next);
        is($pager->total_entries, 10);
        is($pager->offset, 0);
        is($pager->limit, 3);
        my @rows = $response->rows;
        is(0+@rows, 3);
        is_deeply($rows[0], { _id => 1, _key => 1, bar => 'heh1'});
        note Dumper($response->data);
    };
    subtest 'last page' => sub {
        my $response = $client->select(
            table => 'Foo',
            limit => 3,
            offset => 9,
        );
        isa_ok($response, 'Net::Groonga::HTTP::Response');
        my $pager = $response->pager;
        isa_ok($pager, 'Net::Groonga::Pager');
        ok($response->is_success);
        ok(!$pager->has_next);
        is($pager->total_entries, 10);
        is($pager->offset, 9);
        is($pager->limit, 3);
        my @rows = $response->rows;
        is(0+@rows, 1);
        is_deeply($rows[0], { _id => 10, _key => 10, bar => 'heh10'});
    };
};

subtest 'dump' => sub {
    my $response = $client->dump(
        table => 'Foo',
    );
    isa_ok($response, 'Net::Groonga::HTTP::Response');
    ok($response->is_success);
    note $response->data;
};

done_testing;

