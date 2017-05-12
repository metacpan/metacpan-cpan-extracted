use strict;
use warnings;

use Test::More;
use Test::Exception;

dies_ok {
    my $t = Tester->new( db_user => 'noggin' )
} 'dies with no args';

my $t = Tester->new( db_dsn => 'foo' );
can_ok( $t, 'db_conn', 'db_dsn', 'db_user', 'db_password', 'db_attrs' );
can_ok( $t->db_conn, 'dbh', 'txn' );

my $t2 = Tester2->new( foo_dsn => 'bar' );
can_ok( $t2, 'foo_conn', 'foo_user', 'foo_password', 'foo_attrs' );
can_ok( $t2->foo_conn, 'dbh', 'txn' );

done_testing;

BEGIN {
    package Tester;
    use Moose;
    with 'MooseX::Role::DBIx::Connector';

    package Tester2;
    use Moose;
    with 'MooseX::Role::DBIx::Connector' => { connection_name => 'foo' };

}
