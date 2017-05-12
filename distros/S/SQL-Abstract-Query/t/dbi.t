#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use SQL::Abstract::Query;
use Try::Tiny;

try {
    require DBI;
    require DBD::SQLite;
}
catch {
    plan skip_all => 'DBI and DBD::SQLite must be installed to run these tests';
};

unlink('test.db') if -e 'test.db';
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '', {RaiseError=>1, AutoCommit=>1});

my $query = SQL::Abstract::Query->new( $dbh );

$dbh->do(q[
    CREATE TABLE users (
        user_id INTEGER,
        email TEXT,
        is_admin INTEGER DEFAULT 0
    )
]);

{
    my $insert = $query->insert('users', [qw( user_id email )]);

    my $sth = $dbh->prepare( $insert->sql() );

    foreach my $user_id (1..100) {
        $sth->execute(
            $insert->values({ user_id => $user_id, email => 'user' . $user_id . '@example.com' }),
        );
    }

    is(
        count(),
        100,
        '100 users inserted',
    );
}

{
    is( count({is_admin=>1}), 0, 'no admins yet' );

    my $update = $query->update('users', ['is_admin'], {user_id=>{'<=', 'max_user_id'}});

    my $sth = $dbh->prepare( $update->sql() );

    $sth->execute( $update->values({is_admin=>1, max_user_id=>10}) );
    is( count({is_admin=>1}), 10, '10 users updated to be admins' );

    $sth->execute( $update->values({is_admin=>1, max_user_id=>30}) );
    is( count({is_admin=>1}), 30, '20 more (30 total) users updated to be admins' );
}

{
    my $delete = $query->delete('users', {email=>'email'});

    my $sth = $dbh->prepare( $delete->sql() );

    $sth->execute( $delete->values({email => 'user1@example.com'}) );
    is( count(), 99, 'deleted one user' );

    $sth->execute( $delete->values({email => 'user11@example.com'}) );
    $sth->execute( $delete->values({email => 'user31@example.com'}) );
    is( count(), 97, 'delete 2 more users' );
    is( count({is_admin=>1}), 28, '2 of those deleted were admins' );
    is( count({is_admin=>0}), 69, '1 of those deleted were not admins' );
}

done_testing;

sub count {
    my ($where) = @_;
    $where ||= {};

    my ($sql, @bind_values) = $query->select(
        [\'COUNT(*)'],
        'users',
        $where,
    );

    return ( $dbh->selectrow_array( $sql, undef, @bind_values ) )[0];
}
