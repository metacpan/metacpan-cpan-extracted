package Pg::Blobs;
$Pg::Blobs::VERSION = '0.003';
use Moose::Role 2.0401;

requires 'pgblobs_dbh';

=head1 NAME

Pg::Blobs - Blobs management methods for Postgresql related DB modules.

=head2 SYNOPSIS

This is a Moose::Role. Consume it in your DB management class and implement the method
pgblobs_dbh.

Note that blob management in postgresql do not work outside a transaction.

Blobs are just numeric OIDs in postgresql. You will have to store them in a classic OID table column
for later retrieval.

Example:

    package My::DB;
    use Moose;
    with qw/Pg::Blobs/;

    sub pgblobs_dbh{ .. return the dbh connection of your choice ..}
    ...

    package main;
    my $db = .. an instance of My::DB ..;

    #### IMPORTANT: IN A TRANSACTION
    my $blob = $db->pgblobs_store_blob('binary content');
    my $content = $db->pgblobs_fetch_blob($blob);
    etc..

=cut

=head2 pgblobs_create_blob

Creates a Postgresql empty blob (oid) and returns it.

Note that it is not very useful. Use pgblobs_stream_in_blob or
pgblobs_store_blob instead.

Usage:

   my $blob = $this->pgblobs_create_blob()

=cut

sub pgblobs_create_blob{
    my ($self) = @_ ;
    my $dbh = $self->pgblobs_dbh();

    my $oid = $dbh->func($dbh->{pg_INV_WRITE} || $dbh->{pg_INV_READ},'lo_creat') 
	|| confess "CANT CREATE BLOB\n" ;
    return $oid ;
}


=head2 pgblobs_store_blob ($buf)

Stores the given binary content in the postgresql db and return the blob id.

Usage:

   my $blob = $this->pgblobs_store_blob('Full short binary content');


=cut

sub pgblobs_store_blob{
    my ($self , $buf ) = @_ ;
    my $oid = $self->pgblobs_create_blob ;
    my $dbh = $self->pgblobs_dbh();
    my $fh = $dbh->func($oid,
			$dbh->{pg_INV_WRITE},
			'lo_open');
    my $blength = length($buf) ;
    my $nbytes = $dbh->func($fh, $buf, $blength , 'lo_write');
    $dbh->func($fh, 'lo_close');
    return $oid ;
}

=head2 pgblobs_stream_in_blob ($sub)

Pulls data using the given read code, storing it into a new blob.

Returns the new blob id.

Usage:

    my $blob = $this->pgblobs_stream_in_blob(sub{ return 'Next slice of bytes or undef' ;});

=cut

sub pgblobs_stream_in_blob{
  my ($self,$read) = @_;
  my $oid = $self->pgblobs_create_blob();
  my $dbh = $self->pgblobs_dbh();
  my $fh = $dbh->func($oid,$dbh->{pg_INV_WRITE},
                      'lo_open');
  while( defined( my $buf = &{$read}() ) ){
    my $blength = length($buf) ;
    my $nbytes = $dbh->func($fh, $buf, $blength , 'lo_write');
  }
  $dbh->func($fh, 'lo_close');
  return $oid;
}

=head2 pgblobs_stream_out_blob

Streams out the given blob ID in the given write sub and return the number of bytes
retrieved.

Example:

   $s->stream_out_blob(sub{ my $fresh_bytes = shift ; ... ; } , $oid );

=cut

sub pgblobs_stream_out_blob{
  my ($self,$write,$oid) = @_;
  my $dbh = $self->pgblobs_dbh();

  my $fh = $dbh->func($oid ,  $dbh->{pg_INV_READ}, 'lo_open');
  my $buf = '' ;
  my $total_bytes = 0;
  # Read by chunks of 1024
  while( my $nbytes = $dbh->func($fh , $buf, 1024 , 'lo_read') ){
    $total_bytes += $nbytes;
    ## Call write with this chunk
    &{$write}(substr($buf, 0 , $nbytes ));
  }
  return $total_bytes;
}

=head2 pgblobs_fetch_blob ($oid)

Fectches the blob binary content in one go

Usage:

  my $small_content = $this->pgblobs_fetch_blob($blob);

=cut

sub pgblobs_fetch_blob{
    my ($self , $oid ) = @_ ;
    my $dbh = $self->pgblobs_dbh();

    my $fh = $dbh->func($oid ,  $dbh->{pg_INV_READ}, 'lo_open');
    my $content ; 
    my $buf = '' ;
    # Read by chunks of 1024
    while( my $nbytes = $dbh->func($fh , $buf, 1024 , 'lo_read') ){
        $content .= substr($buf, 0 , $nbytes );
    }
    return $content ;
}

1;
