package IO::DB;

# IO::DB object module
# Copyright (c) 2003-2005 by David Bialac
# Rights to use and or modify this code is granted under the terms of the GNU
# Lesser Public license or the Perl Artistic License.

use DBI;
use Carp;
use strict;

our ($VERSION);

$VERSION = "0.1";

=head1 NAME

IO::DB - Database convenience object.

=head1 SYNOPSIS

    use IO::DB;

    my $db = new IO::DB( { db_dsn => 'dbi:Sybase:db01',
                           db_user => 'web',
                           db_pass => 'password' } );

    # Note the lack of a connect!

    my $rows = $db->sql_rows( 'select count(*) from mytable' );

    foreach my $row (@$rows) {
       print $row->{value}, "\n";
    }

    my $hash = $db->sql_hash( 'select name, count(*)
                               from mytable
                               group by name' );

    foreach my $key (keys(%$hash)) {
       print "$key is $hash{$key}\n";
    }

=head1 DESCRIPTION

The IO::DB library was created and is intended as a convenience library.  It
works by reducing clutter in your code caused by using the same redundant
code.  It also works under the philosophy of intelligent code.  That is,
let me tell you to do something and let the code figure out the prerequisits.
This is in part responsible for the lack of an explicit connect function.
It is also responsible for the currently incomplete quote function.  Those who
are adventurous may poke around and try it out.

Back to the topic of connecting, the library will automatically connect to
the database the first time you issue a sql statement.  If for some reason
you need some functionality tied to dbh, you can access it through the dbh
member like this:

   $db->{dbh}->quote( $mycolumndata );

Note that if you haven't executed any sql, this will not work.  If you find
a case where you do need an explicit connect, simply call the private
_connect function like so:

   $db->_connect();

Features eventually slated include an improved 'quote' function which looks
at the table and determines if a field needs quoting or not.  All of this
information will of course be cached to limit the additional load on the
database that this will inevidably cause.

=head1 METHODS

=head2 new

    The new function creates a new instance of the IO::DB object.  It
    should be passed a configuration parameter either through a hash
    or through a configuration object resembling a hash.  The three
    parameters in the configuration are:

       db_dsn  - the DSN string you would normally pass to DBI
       db_user - the username to log into the database with
       db_pass - the password to use or undef if no password

=cut

sub new {
   my $base = shift;
   my $registry = shift;
   my %self = ( 'registry' => $registry );
   my $s = bless \%self, $base;

   return $s;
}

sub _connect {
   my $self = shift;
   my $registry = $self->{registry};

   my $dsn  = $self->{registry}->{db_dsn};
   my $user = $self->{registry}->{db_user};
   my $pass = $self->{registry}->{db_pass};

   if (ref($pass) =~ /HASH/) {
      $pass = "";
   }

   unless ($self->{dbh}) {
      $self->{dbh} = DBI->connect( $dsn, $user, $pass );
   }

   unless ($self->{dbh}) {
      confess "Unable to connect to database! ($dsn/$user/$pass)";
   }
}

=head2 sql_do

    The sql_do function simply privides a wrapper around the DBI 'do'
    statement.  Other than this, it does nothing.  Simply pass the
    sql to execute as the first parameter.

        $db->sql_do("delete from mytable where inactive='Y'");

=cut

sub sql_do {
   my $self = shift;
   my $sql = shift;

   $self->_connect();
   $self->{dbh}->do( $sql );
}

=head2 sql

    The sql function works by wrapping around a prepare statement
    and executing the passed sql.  It supports using paramaters
    (1, 2, 3, ... or ?, ?, ?,...) for the sql.  Coming enhancements
    include caching sth handles to improve performance.

        my $sth = $db->sql( "select count(*) from mytable" );

    -or-

        my $sth = $db->sql( "select count(*) from mytable
                             where a=? and b=?", $a, $b );

=cut

sub sql {
   my $self = shift;
   my $sql = shift;

   $self->_connect();

   my $sth = $self->{dbh}->prepare( $sql );
   my $rv;
   if (scalar(@_)) {
      $rv = $sth->execute( @_ );
   } else {
      $rv = $sth->execute();
   }
   print STDERR "--DBSQL--\n$sql\n" if ($self->{dbh}->errstr);

   return $sth;
}

=head2 sql_rows

    The sql_rows function behaves much like the sql statement, except
    that instead of returning the $sth object, it will instead return
    a reference to an array containing the result set.  Each row will
    have it's values contained within a hash.  Care should be
    taken with this function as large result sets will undoubtedly
    kill the performance of your computer.

        my  $rows = $db->sql_rows( 'select foo, bar from mytable' );

        foreach my $row (@$rows) {
           print "$row->{foo}, $row->{bar}\n";
        }

=cut

sub sql_rows {
   my $self = shift;
   my $sql = shift;

   my @array;

   my $sth;

   if (@_) {
      $sth = $self->sql( $sql, @_ );
   } else {
      $sth = $self->sql( $sql );
   }

   while (my $row = $sth->fetchrow_hashref()) {
      push (@array, $row);
   }

   return \@array;
}

sub get_column_types {
   my $self = shift;
   my $table = shift;


   unless (exists($self->{'.tables'}->{$table})) {
      my ($t, $d);
      if ($table =~ /\.\./) {
         ($d,$t) = split ('\.\.', $table );
         $self->sql("use $d");
      } else {
         $t = $table;
      }
      my $sql = "sp_columns $t";

      my $cols = $self->sql_rows( $sql );
      my %chash = ();
      foreach my $col (@$cols) {
         $chash{$col->{COLUMN_NAME}} = $col->{TYPE_NAME};
      }

      $self->{'.tables'}->{$table} = \%chash;
   }

   return $self->{'.tables'}->{$table};
}

sub get_columns {
   my $self = shift;
   my $table = shift;

   $self->get_column_types($table);
   my @cols = keys(%{$self->{'.tables'}->{$table}});
   return \@cols;
}

=head2 sql_hash

    The sql_hash function is useful for returning two-column
    result sets as a hash rather than as a set of rows.  It again
    behaves in much the same manner as the sql function does.

=cut

sub sql_hash {
        my $self = shift;
        my $sql = shift;

        my $sth;
        if (@_) {
           $sth = $self->sql($sql, @_);
        } else {
           $sth = $self->sql($sql);
        }
        my %return_hash; 

        while (my @row = $sth->fetchrow_array) {
                $return_hash{$row[0]} = $row[1];
        }

        return \%return_hash;
}

=head2 quote

    WARNING: THIS FUNCTION MAY NOT FUNCTION PROPERYLY FOR YOU.
    It is currenty specific to SQL Server and Sybase.

    The quote function is useful for quoting data prior to insertion.
    It has the nice trate that it does datatype lookups on tables
    so you don't have to know what to quote and what not to.  HOWEVER
    it currently will quote functions as though they are strings with
    the notable exception of the getdate() function.

=cut

sub quote {
   my $self = shift;
   my $table = shift;
   my $column = shift;
   my $data = shift;

   $self->get_column_types($table);

   # Null conversion
   unless ($data) {
      return 'NULL';
   }

   # Functions never get quoted, this needs extreme expanding
   if ($data =~ /getdate()/i) {
      return $data;
   }

   if ($self->{'.tables'}->{$table}->{$column} =~ /CHAR|DATE|TEXT|BINARY/i) {
      $self->_connect();
      return $self->{dbh}->quote( $data );
   }
   return $data;
}

sub _disconnect {
   my $self = shift;

   if ($self->{dbh}) {
      $self->{dbh}->disconnect();
      delete ($self->{dbh});
   }
}


sub DESTROY {
   my $self = shift;
   $self->_disconnect();
}

=head1 AUTHOR

David Bialac <dbialac@yahoo.com>

=head1 VERSION

IO::DB version 0.1, released on 22 June 2005.

=head1 COPYRIGHT

Copyright (C) 2003-2005 David Bialac.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser Public License or the Perl
Artistic License at your discression.

=cut

1;
