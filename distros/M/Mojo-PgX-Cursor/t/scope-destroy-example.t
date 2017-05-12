use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojo::JSON qw(encode_json);

use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

require Mojo::PgX::Cursor;

my $pg = Mojo::PgX::Cursor->new($ENV{TEST_ONLINE});
my $db = $pg->db;

my $orig_destroy = \&Mojo::PgX::Cursor::Cursor::DESTROY;
my $destroy_rv;
{
    no warnings 'redefine';
    *Mojo::PgX::Cursor::Cursor::DESTROY = sub {
        $destroy_rv = $orig_destroy->(@_);
    }
}

{
    my $tx = $db->begin;

    $tx->db->query('set client_min_messages=WARNING');
    $tx->db->query('drop table if exists tx_test');
    $tx->db->query(
        'create table if not exists tx_test (
        id   serial primary key,
        name text,
        jdoc jsonb
        )'
    );
    # Put $results in its own scope so it is destroyed before
    # transaction.  Otherwise the transaction will kill the cursor
    # and the cursor's destroy will error.
    {
        my $results = $tx->db->cursor('select * from tx_test');
    }
    # Does Perl need a statement between scopes to avoid bundling
    # their cleanup together?  Removing this `1;` will make test
    # fail.  This test is really a demonstration that we can use
    # scoping to ensure order of destruction.
    1;
}
ok($destroy_rv, 'DESTROY did not crash');

done_testing();
