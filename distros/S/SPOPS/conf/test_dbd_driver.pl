#!/usr/bin/perl

# $Id: test_dbd_driver.pl,v 3.0 2002/08/28 01:16:31 lachoy Exp $

# test_dbd_driver.pl

# See whether a DBD driver will support SPOPS. Currently this is
# pretty rudimentary :-)

# Edit the file 'test_dbd_driver.dat' with configuration information
# for your driver and connection.

use strict;
use DBI  qw( :sql_types );

use constant CONFIG_FILE => 'test_dbd_driver.dat';
use constant DEFAULT_SQL => 'SELECT * FROM %s WHERE 1 = 0';

my $VERSION = '0.01';

{
    # Read in the config and ensure we have the right info

    my $conf = read_config();
    if ( my $required = test_config( $conf ) ) {
        die "Please specify the required fields in the configuration. ",
            "Errors found:\n$required\n";
    }

    # Make the connection

    my $full_dsn = "DBI:$conf->{dbd}:$conf->{dsn}";
    my $dbh = DBI->connect( $full_dsn, $conf->{username}, $conf->{password} );
    unless ( $dbh ) {
        die "Cannot connect with the information given.\nDBI DSN: $full_dsn\n",
            "Username: $conf->{username}\nPassword: $conf->{password}\n",
            "Please modify the file (", CONFIG_FILE, ") and rerun.\n";
    }
    $dbh->{RaiseError} => 1;
    $dbh->{PrintError} => 0;

    # Create the SQL and run

    my $sql = $conf->{sql} || sprintf( DEFAULT_SQL, $conf->{table} );
    my ( $sth );
    my $sth = eval { $dbh->prepare( $sql ) };
    die "Cannot prepare SQL:\n$sql\nError: $\n@"  if ( $@ );
    die "Statement handle not created!\n"         unless ( $sth );

    my $rv = eval { $sth->execute };
    die "Cannot execute SQL:\nError: $@\n"        if ( $@ );
    die "False value returned from execute!\n"    unless ( $rv ) ;

    my $fields = $sth->{NAME};
    my $types  = $sth->{TYPE};
    my ( @field_info );
    my ( $longest_field, $longest_type, $cannot_quote );
    for ( my $i = 0; $i < scalar @{ $fields }; $i++ ) {
        my ( $english, $val ) = english_sql_type( $types->[ $i ] );
        my $quoted = eval { $dbh->quote( $val, $types->[ $i ] ) };
        if ( $@ ) { $quoted = 'n/a'; $cannot_quote++; }

        my $null = eval { $dbh->quote( undef, $types->[ $i ] ) };
        if ( $@ ) { $null = 'n/a' }

        my $item = { field        => $fields->[ $i ],
                     dbi_type     => $types->[ $i ],
                     english_type => $english,
                     quoted       => $quoted,
                     null         => $null };
        $longest_field = ( $longest_field < length $item->{field} )
                           ? length $item->{field} : $longest_field;
        $longest_type  = ( $longest_type < length $item->{english_type} )
                           ? length $item->{english_type} : $longest_type;
        push @field_info, $item;
    }

    my $fmt = "%-${longest_field}s   %-${longest_type}s   %8s   %-8s   %s\n";

    print "\nInfo for Driver: $conf->{dbd}\n",
          "Date:            ", scalar localtime, "\n",
          "Script version:  $VERSION\n\n";
    printf( $fmt, "Field", "Type", "DBI Type", "Quoted", "Null" );
    print '=' x 60, "\n";
    foreach my $inf ( @field_info ) {
        printf( $fmt, $inf->{field}, $inf->{english_type}, $inf->{dbi_type}, $inf->{quoted}, $inf->{null} );
    }

    if ( $cannot_quote ) {
        print "\nType discovery ok, but the two-argument 'quote( \$val, ",
              "\$dbi_type )' does not work properly\n";
    }
    else {
        print "\nThis driver seems capable of being used for SPOPS.\n";
    }

    print "\n\nAll done!\n";

    $sth->finish;
    $dbh->disconnect;
}


# If you're interested to know where this list came from, do:
#
#  find /usr/lib/perl5 -name "dbi_sql.h" -print
#
# And check out the contents.

sub english_sql_type {
    my ( $type ) = @_;
    return ( "SQL_CHAR", "blah" )         if ( $type == SQL_CHAR );
    return ( "SQL_NUMERIC", 42.87 )       if ( $type == SQL_NUMERIC );
    return ( "SQL_DECIMAL", 42.87 )       if ( $type == SQL_DECIMAL );
    return ( "SQL_INTEGER", 4287 )        if ( $type == SQL_INTEGER );
    return ( "SQL_SMALLINT", 42 )         if ( $type == SQL_SMALLINT );
    return ( "SQL_FLOAT", 42.87891 )      if ( $type == SQL_FLOAT );
    return ( "SQL_REAL", 42.87891 )       if ( $type == SQL_REAL );
    return ( "SQL_DOUBLE", 42.87891 )     if ( $type == SQL_DOUBLE );
    return ( "SQL_DATE", "2001-02-14" )   if ( $type == SQL_DATE );
    return ( "SQL_TIME", "09:52:01" )     if ( $type == SQL_TIME );
    return ( "SQL_TIMESTAMP", "2001-02-14 09:52:01" )    if ( $type == SQL_TIMESTAMP );
    return ( "SQL_VARCHAR", "blah" )      if ( $type == SQL_VARCHAR );
    return ( "SQL_LONGVARCHAR", "blah" )  if ( $type == SQL_LONGVARCHAR );
    return ( "SQL_BINARY", "blah" )       if ( $type == SQL_BINARY );
    return ( "SQL_VARBINARY", "blah" )    if ( $type == SQL_VARBINARY );
    return ( "SQL_LONGVARBINARY", "blah" ) if ( $type == SQL_LONGVARBINARY );
    return ( "SQL_BIGINT", 4287 )         if ( $type == SQL_BIGINT );
    return ( "SQL_TINYINT", 42 )          if ( $type == SQL_TINYINT );
    return ( "SQL_BIT", 1 )               if ( $type == SQL_BIT );
    return ( "SQL_WCHAR", "wblah" )       if ( $type == SQL_WCHAR );
    return ( "SQL_WVARCHAR", "wblah" )    if ( $type == SQL_WVARCHAR );
    return ( "SQL_WLONGVARCHAR", "wblah" ) if ( $type == SQL_WLONGVARCHAR );
    return ( "(unknown type! <$type>)", undef );
}

sub read_config {
    my ( $config_file ) = @_;
    $config_file ||= CONFIG_FILE;
    open( CONF, $config_file ) || die "Cannot open file ($config_file): $!";
    my %conf = ();
    while ( <CONF> ) {
        next if ( /^\s*$/ );
        next if ( /^\s*\#/ );
        s/^\s+//;
        s/\s+$//;
        my ( $key, $value ) = split /\s+/;
        $conf{ $key } = $value;
    }
    return \%conf;
}

sub test_config {
    my ( $conf ) = @_;
    my ( @msg );
    unless ( $conf->{dbd} )   { push @msg, "DBD driver not defined (key: dbd)" }
    unless ( $conf->{table} ) { push @msg, "Table name not defined (key: table)" }
    unless ( $conf->{dsn} )   { push @msg, "DSN not defined (key: dsn)" }
    return undef unless ( scalar @msg );
    return join( "\n", @msg );
}

=pod

=head1 NAME

test_dbd_driver.pl - Perform tests on a DBD driver to see if it may work with SPOPS

=head1 SYNOPSIS

 # Create a table to test -- test_dbd_driver.sql has a sample. (This
 # is database-specific.)

 # Mysql

 mysql --user=root --password=password test < test_dbd_driver.sql

 # Sybase/MS SQL

 isql -Usa -Dmaster -Ppassword -i test_dbd_driver.sql

 # Postgres

 psql -U postgres test < test_dbd_driver.sql

 # Edit the file 'test_dbd_driver.dat' with connection info

 dbd         mysql
 dsn         test
 usename     nobody
 password    nobody
 table       spopstest

 # Run the test

 perl test_dbd_driver.pl

=head1 DESCRIPTION

To come...

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
