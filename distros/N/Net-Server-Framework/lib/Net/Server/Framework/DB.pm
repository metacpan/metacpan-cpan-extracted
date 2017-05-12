#!/usr/bin/perl -I../lib -w

# a database module abstracting the "magic" of what we need for the
# general daemon
# the static config file is in etc/db.conf

package Net::Server::Framework::DB;

use strict;
use DBI;
use Switch;
use Net::Server::Framework::Config;
use Data::Dumper;
use warnings;
use Carp;
use vars qw(@EXPORT $VERSION);

our ($VERSION) = '1.25';

sub dbconnect {
    my $scope = shift;
    my $conf  = Net::Server::Framework::Config::file2hash("etc/db.conf");
    my $host;
    my $dsn;
    switch ( $conf->{ $scope . "_type" } ) {
        case /sqlite/ {
            $dsn = "DBI:SQLite:dbname=" . $conf->{ $scope . "_host" };
        }
        case /mysql/ {
            if ( $conf->{ $scope . "_host" } =~ m{sock$}xm ) {
                $host = "mysql_socket=" . $conf->{ $scope . "_host" };
            }
            else {
                $host = "host=" . $conf->{ $scope . "_host" };
            }
            $dsn = "DBI:mysql:database=" . $conf->{ $scope . "_db" } . q{:} . $host;
        }
        case /pgsql/ {
            if ( $conf->{ $scope . "_host" } =~ m{local$}xm ) {
                $host = q{}; 
            }
            else {
                $host = "host=" . $conf->{ $scope . "_host" };
            }
            $dsn = "DBI:Pg:dbname=" . $conf->{ $scope . "_db" } . q{;} . $host;
        }
    }

    #$log->debug("HOST: $host");
    my $dbh = DBI->connect(
        $dsn,
        $conf->{ $scope . "_user" } || q{},
        $conf->{ $scope . "_pass" } || q{},
        {
            RaiseError => 0,
            PrintError => 1,
            AutoCommit => 1
        }
    ) or carp( "Error while connecting " . DBI::errstr );

    #    or die;
    return $dbh;
}

sub get {
    my $request = shift;

    my $select;
    switch ( $request->{key} ) {

        # SELECT statement go here ############
        case "ID" { $select = qq /SELECT id AS _one, hash, ts, status FROM spool WHERE id=?/; }
        case "virgin" { $select = qq /SELECT id AS _one, hash, ts, status FROM spool WHERE id=? AND status <> 'virgin'/; }
        case "host" { $select = qq /SELECT host AS _one, port FROM services WHERE service = ?/; }
        case "status" { $select = qq /SELECT service AS _one, host, port FROM services WHERE status = ?/; }
        case "service" { $select = qq /SELECT service AS _one, host, port, lastcheck, startup, status FROM services WHERE service = ?/; }
        case "auth" { $select = qq /SELECT username AS _one, password FROM users WHERE username = ? AND active=TRUE/; }
        else { return "not implemented" }
        #######################################
    }
    my $sth = $request->{dbh}->prepare($select);
    if ( defined $request->{term} ) {
        $sth->execute( $request->{term} );
    }
    else {
        $sth->execute();
    }
    my $result;
    while ( my $line = $sth->fetchrow_hashref() ) {
        my ( $ONE, $TWO );
        $ONE = delete( $line->{_one} );
        if ( exists $line->{_two} ) { $TWO = delete( $line->{_two} ) }
        my ( $h1, $h2 );
        foreach my $key ( keys %{$line} ) {
            if ($TWO) {
                foreach my $key ( keys %{$line} ) {
                    if ( defined $request->{array} ) {
                        $h2->{$TWO}->{$key} = $line->{$key};
                    }
                    else {
                        $result->{$ONE}->{$TWO}->{$key} = $line->{$key};
                    }
                }
            }
            else {
                if ( defined $request->{array} ) {
                    $h1->{$ONE}->{$key} = $line->{$key};
                }
                else {
                    $result->{$ONE}->{$key} = $line->{$key};
                }
            }
        }
        if ( defined $request->{array} ) {
            if ( defined $h1 ) {
                push( @{ $result->{$ONE} }, $h1->{$ONE} );
            }
            if ( defined $h2 ) {
                push( @{ $result->{$ONE}->{$TWO} }, $h2->{$TWO} );
            }
        }
    }
    return $result;
}

sub put {
    my $request = shift;

    my ( $key, $value );
    foreach my $k ( keys %{ $request->{data} } ) {
        if ( $request->{data}->{$k} =~ m{^\d+$}xm ) {
            $key   .= $k . q{,};
            $value .= $request->{data}->{$k} . q{,};
        }
        elsif ( $request->{data}->{$k} =~ m{^[A-Z]+\(\)$}xm ) {
            $key   .= $k . q{,};
            $value .= $request->{data}->{$k} . q{,};
        }
        else {
            $key   .= $k . q{,};
            $value .= q{'} . $request->{data}->{$k} . q{',};
        }
    }
    chop($key);
    chop($value);
    my $string = 'INSERT INTO ';
    $string = 'REPLACE INTO ' if (defined $request->{replace_into});
    my $insert =
      $string . $request->{table} . " ($key) VALUES ($value)";
    print STDERR $insert . "\n";
    $request->{dbh}->do($insert)
      or carp(DBI::errstr);
    #TODO test this line with all DBs!
    #my $id =  $request->{dbh}->last_insert_id(undef,undef,$request->{table},undef);
    #return ($id ? $id : 0);
    return ;
}

sub do {
    my $request = shift;
    my $statement;

    switch ( $request->{key} ) {
        case "del" { $statement = qq /DELETE FROM spool WHERE ID = ?/; }
        case "vacuum" { $statement = qq /VACUUM/; }
        else { return "not implemented" }

    }

    my $sth = $request->{dbh}->prepare($statement)
      or carp(DBI::errstr);
    if ( defined $request->{term} ) {
        $sth->execute( $request->{term} );
    }
    else {
        $sth->execute();
    }
    return 0;
}

1;

=head1 NAME

Net::Server::Framework::DB - DBI wrapper for Net::Server::Framework
based daemons


=head1 VERSION

This documentation refers to C<Net::Server::Framework::Auth> version 1.25.


=head1 SYNOPSIS

A typical invocation looks like this:

    my $dbh = Net::Server::Framework::DB::dbconnect($DB);
    my $res = Net::Server::Framework::DB::get( { 
                dbh => $dbh, 
                key => 'host', 
                term => $service 
    } );


=head1 DESCRIPTION

This is a lib that is used to collect all SQL statements from one
application. Typically you end up with one DB.pm for many daemons that
are used in one project. The DB.pm provided with the package covers only
the internal functions needed by the platform itself like registry and
queue. The syntax is really minimal and that was the purpose. Small easy
queries are fast for high load environments.

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 dbconnect

Connect to a database. Supported databases in the moment are SQLite
(default) MySQL and PostgreSQL. Adding more databases is straight
forward.

=head2 get

Define your queries here. This is the central place for SQL in a
application written in C<Net::Server::Framework>. All queries have an
identifier and are limited to a maximum of three dimensions in the
output hash.

=head2 put

This inserts data into the database

=head2 do

All stuff that is not an insert or an update goes here. Predefined
queries as in get.

=head1 CONFIGURATION AND ENVIRONMENT

The library needs a working etc/db.conf file.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to 
Lenz Gschwendtner ( <lenz@springtimesoft.com> )
Patches are welcome.

=head1 AUTHOR

Lenz Gschwendtner ( <lenz@springtimesoft.com> )



=head1 LICENCE AND COPYRIGHT

Copyright (c) 
2007 Lenz Gschwerndtner ( <lenz@springtimesoft.comn> )
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
