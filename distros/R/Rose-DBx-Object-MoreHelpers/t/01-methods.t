#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Rose::DBx::TestDB;
use Rose::DB::Object;

#use Data::Dump qw( dump );
use_ok('Rose::DBx::Object::MoreHelpers');

{

    package MyRDBO;
    @MyRDBO::ISA = qw(Rose::DB::Object Rose::DBx::Object::MoreHelpers);

    MyRDBO->meta->setup(
        table => 'no_such_table',

        columns => [
            id   => { type => 'varchar' },
            name => { type => 'varchar', length => 16 },
        ],

        primary_key_columns => [ 'id', 'name' ],
    );

    sub init_db { return Rose::DBx::TestDB->new }

}

ok( my $rdbo = MyRDBO->new( id => '1;2', name => '3/4' ), "new rdbo object" );
ok( my $pk_uri_escaped = $rdbo->primary_key_uri_escaped(),
    "get pk uri escaped" );
is( $pk_uri_escaped, "1%3b2;;3%2f4", "pk escaped" );

# serial might be a bigint

{

    package MyBigRDBO;
    @MyBigRDBO::ISA = qw(Rose::DB::Object Rose::DBx::Object::MoreHelpers);

    MyBigRDBO->meta->setup(
        table => 'no_such_table_with_bigint_pk',

        columns => [
            id   => { type => 'bigserial', not_null => 1, },
            name => { type => 'varchar',   length   => 16 },
        ],

        primary_key_columns => ['id'],
    );

    sub init_db { return Rose::DBx::TestDB->new }

}

my $bignum = Math::BigInt->new(9223372036854775809876540);
ok( my $big_rdbo = MyBigRDBO->new( id => $bignum, name => '3/4' ),
    "new rdbo object" );

#diag( dump $big_rdbo->meta );
ok( my $big_pk_uri_escaped = $big_rdbo->primary_key_uri_escaped(),
    "get pk uri escaped" );
is( $big_pk_uri_escaped, $bignum, "pk is bigint escaped" );

