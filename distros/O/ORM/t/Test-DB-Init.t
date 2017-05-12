#!/usr/bin/perl

use lib "t";
use Test::More tests => 2;
use IO::File;

BEGIN
{
    unlink 't/Test.db';
    use_ok( 'Test::ORM' );
}

$error = ORM::Error->new;

if( Test::ORM->_db->isa( 'ORM::Db::DBI::SQLite' ) )
{
    $sql_file = IO::File->new( 't/Test-DB.SQLite.sql' );
    $sql_file->read( $sql, 100000 );

    @queries = split /;/, $sql;

    for $query ( @queries )
    {
        Test::ORM->_db->do
        (
            error => $error,
            query => $query,
        );
    }
}

ok( !$error->fatal, 'db_init' );
print $error->text;

$res = Test::ORM->_db->select
(
    query => 'select count( distinct id ) as c from Dummy',
);

print $res->next_row->{c},"\n";
$res = undef;
