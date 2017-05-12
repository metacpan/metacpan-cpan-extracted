#!/usr/bin/perl

use strict;
use DBI;

# Fill in the following variables

my $DSN   = 'DBI:mysql:test';
my $USER  = '';
my $PASS  = '';
my $TABLE = '';

# You probably don't need to change this

my $DUMMY = 'SELECT * FROM %s WHERE 1 = 0';

{
    my $dbh = DBI->connect( $DSN, $USER, $PASS )
                    || die "Cannot connect: $DBI::errstr";
    $dbh->{RaiseError} = 1;
    my $sql = sprintf( $DUMMY, $TABLE );
    print "Preparing [$sql]\n";
    my $sth = $dbh->prepare( $sql );
    $sth->execute;
    my @names = @{ $sth->{NAME} };
    my @types = @{ $sth->{TYPE} };
    $sth->finish;
    $dbh->disconnect;
    printf( "%-15s %s\n", 'NAME', 'SQL TYPE' );
    print "=" x 30, "\n";
    for ( my $i = 0; $i < scalar @names; $i++ ) {
        printf( "%-15s %s\n", $names[ $i ], $types[ $i ] );
    }
}
