# Copyright (c) 2003 William Goedicke. All rights reserved. This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

=head1 NAME

PeopleSoft - Procedural interface for working with PeopleSoft
applications.

=head1 SYNOPSIS

 use PeopleSoft;
 my $dbh = get_dbh( $username, $password, $SID );
 my $tbl_name_aref = get_tbl_names( 'table_name_spec', $dbh);
 my $tbl_name_aref = where_from( $view_name, $dbh );
 if ( is_view($name, $dbh) )
 my $count = get_rec_count( $tbl_name, $dbh );
 if ( table_exists($tbl_name, $dbh) ) {...}
 my $metadata_href = get_fld_metadata_href( $tbl_name, $dbh );

=cut

use DBI;
use strict;
use Data::Dumper; 

package PeopleSoft;
use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
$VERSION = '1.05';
@ISA = qw(Exporter);

@EXPORT = qw(get_tbl_names
	     get_dbh
	     get_rec_count
	     is_view 
	     table_exists
	     where_from
	     get_fld_metadata_href
	     make_ins_stmt
	    );

=head1 DESCRIPTION

This module provides a set of simple table query and manipulation
functions.

The following functions are provided (and exported) by this module:

=cut

# --------------------------------- get_dbh()

=over 3

=item get_dbh($username, $password, $SID)

The get_dbh() function will return a database handle (courtesy of
DBI/DBD) for use in accessing the database.  It returns C<undef> if it
fails.

=back

=cut

sub get_dbh {
  my ( $username, $password, $SID ) = @_;

  my $dbh = DBI->connect( "dbi:Oracle:${SID}", $username, $password,
			  { PrintError => 1,
			    LongReadLen => 16 * 1024,
			    RaiseError => 0,
			    AutoCommit => 0} 
			) or die $DBI::errstr;
  return $dbh;
}
# --------------------------------- 

=over 3

=item get_table_names('table_name_spec', $dbh)

Get all the table names which match I<table_name_spec> from the
database tied to $dbh.  I<table_name_spec> should be in a form
appropriate for insertion into a SQL where clause (e.g. 'PS_%').

Returns an empty list if it fails.

=back

=cut

sub get_tbl_names {
  my ( $name_spec, $dbh ) = @_;
  my ( @names, @results );

  my $sql_cmd = "select table_name from all_tables where table_name like '$name_spec'";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( @results = $sth->fetchrow_array ) { 
    push(@names, @results);
  }
  $sth->finish;

  return \@names;
}
# --------------------------------- 

=over 3

=item get_rec_count( $tbl_name, $dbh );

Returns the number of records in a table.

=back

=cut

sub get_rec_count {
  my ( $tbl_name, $dbh ) = @_;
  my ( $count, $result );

  my $sth = $dbh->prepare("select count(*) from $tbl_name");
  if ( defined $sth ) {
    $sth->execute;
    while ( ( $result ) = $sth->fetchrow_array ) { 
      $count = $result;
    }
  }
  $sth->finish;

  return $count;
}

# --------------------------------- 

=over 3

=item tbl_exists( $tbl_name, $dbh )

Tests for the existence of I<$tbl_name>.  If the table exists 1 is
returned otherwise 0 is returned.  Typical use would be:

if( tbl_exists($tbl_a, $dbh_a) and tbl_exists($tbl_b, $dbh_b) ) {...}

=back

=cut

sub tbl_exists {
  my ( $tbl_name, $dbh ) = @_;
  my ( @results );

  my $sql_cmd = "select table_name from all_tables where table_name like '$tbl_name'";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while ( @results = $sth->fetchrow_array ) { 
    if ( length(@results) == 0 ) { return 0; }
    else { return 1; }
  }
}
# --------------------------------- Query the database and return metadata hashref

=over 3

=item get_fld_metadata_href( $tbl_name, $dbh )

This function returns a reference to a hash keyed by field name.  For
every field in I<$tbl_name> the hash contains attributes for: data
type, precision and nullable.  Typical use would be:

 $metadata = get_fld_metadata_href( $tbl, $dbh );
 foreach my $field ( keys( %{$metadata} ) ) {
   print "Field $field has data type $$metadata{$field}->{TYPE}\n";
   print "Field $field has size $$metadata{$field}->{PRECISION}\n";
   if ( $$metadata{$field}->{NULLABLE} ) { print "Field $field accepts nulls\n";
 }

=back

=cut

sub get_fld_metadata_href {
  my ( $tbl_name, $dbh ) = @_;
  my ($nullable, $field, $metadata, %TYPES, $desc);
  my $i = -10;

  foreach $desc ( qw(WLONGVARCHAR WVARCHAR WCHAR BIT TINYINT BIGINT
		     LONGVARBINARY VARBINARY BINARY LONGVARCHAR
		     NA CHAR NUMERIC DECIMAL INTEGER SMALLINT FLOAT 
		     REAL DOUBLE DATE TIME TIMESTAMP VARCHAR) ) {
    $TYPES{$i++} = $desc;
  }

  my $sql_cmd = "select * from $tbl_name where ROWNUM = 1";

  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute();

  for ( my $i=0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
    if ( $sth->{NULLABLE}->[$i] != 1 ) {
      $nullable = 0;
    } else {
      $nullable = 1;
    }
    my $field = $sth->{NAME}->[$i];
    $$metadata{$field}->{TYPE} = $TYPES{$sth->{TYPE}->[$i]};
    $$metadata{$field}->{NULLABLE} = $nullable;
    $$metadata{$field}->{PRECISION} = $sth->{PRECISION}->[$i];
  }
  $sth->finish();
  return $metadata;
}
# ---------------------------------------------------- print_insert_statement

=over 3

=item make_ins_stmt($src_md_href,$dest_md_href,$tbl,$src_data_href)

This function returns a SQL insert statement.  It is used to migrate
data between tables with "slightly" different table structures.  This
is accomplished by inserting only data for fields that have the same
name and data type.  It then creates default values for not-nullable
fields in the destinition table that otherwise would not get values.
This is particularly useful in migrating data to different versions of
PeopleSoft applications.

Typical usage is:


 $src_md_href = get_fld_metadata_href( $tbl, $src_dbh );
 $dest_md_href = get_fld_metadata_href( $tbl, $dest_dbh );

  while( $data_href = $sth->fetchrow_hashref ) {
     $insert_sql_script .= make_ins_stmt($src_md_href, $dest_md_href, $tbl, $data_href);
     $insert_sql_script .= "\n";
  }

=back

=cut

sub make_ins_stmt {
  my ( $src_fld_metadata_href, $dest_fld_metadata_href, $dest_tbl_name, $src_data_href ) = @_;
  my ( $name, @fnames, @dvals, $ins_stmt, %seen );

  my %src_metadata = %{$src_fld_metadata_href};
  my %dest_metadata = %{$dest_fld_metadata_href};
  my %src_data = %{$src_data_href};

  my @all_fields = grep { ! $seen{$_} ++ } ( keys(%src_metadata), keys(%dest_metadata) );

  $ins_stmt = "insert into $dest_tbl_name (";
  foreach $name ( @all_fields ) { 
    if ( ! defined $dest_metadata{$name}->{TYPE} ) { next; }
    push @fnames, $name; 
  }
  $ins_stmt .= join ",", @fnames;
  $ins_stmt .= ") values (";
  foreach $name ( @fnames ) {
    if ( ! defined $src_metadata{$name}->{TYPE} ) {
      if ( $dest_metadata{$name}->{TYPE} =~ /DATE/ ) {
	push @dvals, "'01-JAN-00'";
      }
      elsif ( $dest_metadata{$name}->{TYPE} =~ /CHAR/ ) {
	push @dvals, "' '";
      }
      elsif ( $dest_metadata{$name}->{TYPE} =~ /BIN/ or
	      $dest_metadata{$name}->{TYPE} =~ /INT/ or
	      $dest_metadata{$name}->{TYPE} =~ /FLOAT/ or
	      $dest_metadata{$name}->{TYPE} =~ /NUMERIC/ or
	      $dest_metadata{$name}->{TYPE} =~ /DECIMAL/ or
	      $dest_metadata{$name}->{TYPE} =~ /REAL/ or
	      $dest_metadata{$name}->{TYPE} =~ /DOUBLE/ ) {
	push @dvals, 0;
      }
      else { 
	print "Uh oh!  I didn't recognize the field type $dest_metadata{$name}->{TYPE}.\n";
	print "You'ld best add it to the print_insert_statment function.\n";
      }
    }
    else {
      if ( $dest_metadata{$name}->{TYPE} =~ /DATE/ ) {
	push @dvals, "'$src_data{$name}'";
      }
      elsif ( $dest_metadata{$name}->{TYPE} =~ /CHAR/ ) {
	push @dvals, "'$src_data{$name}'";
      }
      elsif ( $dest_metadata{$name}->{TYPE} =~ /BIN/ or
	      $dest_metadata{$name}->{TYPE} =~ /INT/ or
	      $dest_metadata{$name}->{TYPE} =~ /FLOAT/ or
	      $dest_metadata{$name}->{TYPE} =~ /NUMERIC/ or
	      $dest_metadata{$name}->{TYPE} =~ /DECIMAL/ or
	      $dest_metadata{$name}->{TYPE} =~ /REAL/ or
	      $dest_metadata{$name}->{TYPE} =~ /DOUBLE/ ) {
	push @dvals, $src_data{$name};
      }
      else { 
	print "Uh oh!  I didn't recognize the field type of $name.\n";
	print "You'ld best add it to the print_insert_statment function.\n";
      }
    }
  }
  $ins_stmt .= join ",", @dvals;
  $ins_stmt .= ")";

  return $ins_stmt;
}
#-----------------------------------------------------------------

=over 3

=item where_from($view_name, $dbh)

This function returns a reference to an array of the names of all the
tables which are used to create the view.  This is useful when
deriving table loading sequences.

=back

=cut

sub where_from {
  use Data::Dumper;
  my ( $view_name, $dbh ) = @_;
  my ( $sql_text, @results, %utabs, @tabs, @t2, @all_tabs, %ah );

  my $sql_cmd = "select text from all_views where view_name = '$view_name'";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while( @results = $sth->fetchrow_array ) { 
    $sql_text .= $results[0];
  }
  @tabs = $sql_text =~ 
    m/# -- required part:	
    \s+FROM\s+
      \w+			# table name
	\s*			# normal space after the table name
	  # -- optional part:
	  (?:\w+)?		# table abbrv
	    # -- and any number of:
	    (?:\s*,\s*\w+	# a comma and table name, with optional space.
	     (?:\s*\w+)?)*	# optional space, optional table abbrv.
	       /xg;

  foreach ( @tabs ) {
    @t2 = $_ =~
      m/
	\s* (?:FROM|,) \s* (\w+) (?:\s+\w+)*/xg;
    foreach ( @t2 ) {
      $ah{$_} = '';
    }
  }

  push @all_tabs, keys(%ah);

  return \@all_tabs;
}
#-----------------------------------------------------------------

=over 3

=item is_view($name, $dbh)

This function returns true (i.e. 1) if the given name is the name
of a view in the $dbh.

=back

=cut

sub is_view {
  use Data::Dumper;
  my ( $name, $dbh ) = @_;
  my ( $sql_text, @results, %utabs, @tabs, @t2, @all_tabs, %ah );

  my $sql_cmd = "select view_name from all_views where view_name = '$name'";
  my $sth = $dbh->prepare($sql_cmd);
  $sth->execute;
  while( @results = $sth->fetchrow_array ) { 
    return 1;
  }

  return undef;
}
