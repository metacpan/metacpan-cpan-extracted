package Sedna;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = 
  ( 'all' => 
    [ qw(
            BULK_LOAD_PORTION
            QUERY_EXECUTION_TIME
            SEDNA_AUTHENTICATION_FAILED
            SEDNA_AUTOCOMMIT_OFF
            SEDNA_AUTOCOMMIT_ON
            SEDNA_BEGIN_TRANSACTION_FAILED
            SEDNA_BEGIN_TRANSACTION_SUCCEEDED
            SEDNA_BOUNDARY_SPACE_PRESERVE_OFF
            SEDNA_BOUNDARY_SPACE_PRESERVE_ON
            SEDNA_BULK_LOAD_FAILED
            SEDNA_BULK_LOAD_SUCCEEDED
            SEDNA_CLOSE_SESSION_FAILED
            SEDNA_COMMIT_TRANSACTION_FAILED
            SEDNA_COMMIT_TRANSACTION_SUCCEEDED
            SEDNA_CONNECTION_CLOSED
            SEDNA_CONNECTION_FAILED
            SEDNA_CONNECTION_OK
            SEDNA_DATA_CHUNK_LOADED
            SEDNA_DEBUG_ON
            SEDNA_DEBUG_OFF
            SEDNA_ERROR
            SEDNA_GET_ATTRIBUTE_SUCCEEDED
            SEDNA_LOG_FULL
            SEDNA_LOG_LESS
            SEDNA_NEXT_ITEM_FAILED
            SEDNA_NEXT_ITEM_SUCCEEDED
            SEDNA_NO_ITEM
            SEDNA_NO_TRANSACTION
            SEDNA_OPEN_SESSION_FAILED
            SEDNA_OPERATION_SUCCEEDED
            SEDNA_QUERY_FAILED
            SEDNA_QUERY_SUCCEEDED
            SEDNA_READONLY_TRANSACTION
            SEDNA_RESET_ATTRIBUTES_SUCCEEDED
            SEDNA_RESULT_END
            SEDNA_ROLLBACK_TRANSACTION_FAILED
            SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED
            SEDNA_SESSION_CLOSED
            SEDNA_SESSION_OPEN
            SEDNA_SET_ATTRIBUTE_SUCCEEDED
            SEDNA_TRANSACTION_ACTIVE
            SEDNA_UPDATE_FAILED
            SEDNA_UPDATE_SUCCEEDED
            SEDNA_UPDATE_TRANSACTION
       ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.004;
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Sedna::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}
require XSLoader;
XSLoader::load('Sedna', $VERSION);

sub setConnectionAttr {
  my ($self, %params) = @_;
  for (keys %params) {
    my $meth = 'setConnectionAttr_'.$_;
    $self->$meth($params{$_});
  }
}

sub getConectionAttr {
  my ($self, @params) = @_;
  return map {
    my $meth = 'getConnectionAttr_'.$_;
    $_ => $self->$meth($_);
  } @params;
}


1;
__END__

=head1 NAME

Sedna - Driver to connect on the Sedna XML database

=head1 SYNOPSIS

  use Sedna;
  my $conn = Sedna->connect($url,$dbname,$login,$pass);
  $conn->execute("for $x in collection('my-collection') return $x");
  while ($conn->next) {
    my ($buf, $xml);
    while ($conn->getData($buf, 512)) {
      $xml .= $buf;
    }
    say $xml;
  }

=head1 OVERVIEW

Sedna is a XML database and you interact with it using XQuery. This
driver is a direct mapping of the C driver available in the Sedna
distribution, but the code is brought here since they only provide a
static build of the library.

This module will croak on failures, so error handling should be
implemented in terms of eval.

=head1 METHODS

=over

=item Sedna->connect($url, $dbname, $login, $password)

This method is used to stablish a new connection.

=item $conn->setConnectionAttr(%options)

This method can be used to set various connection attribute
parameters. This method is a convenience method for each of the
setConnectionAttr_* methods. Note that you should use the Sedna
constants when you send the values for that attributes, even if the
attribute looks simply as a boolean value.

=item $conn->getConnectionAttr(@options)

Returns a hash with the values for all the requested options. This is
just a convenience method for each of the getConnectionAttr_* methods.

=item $conn->setConnectionAttr_AUTOCOMMIT($value)

=item $conn->getConnectionAttr_AUTOCOMMIT( )

Accessors for the autocommit setting for this connection. The possible
values for this attribute are SEDNA_AUTOCOMMIT_ON and
SEDNA_AUTOCOMMIT_OFF.

=item $conn->setConnectionAttr_SESSION_DIRECTORY($dir)

=item $conn->getConnectionAttr_SESSION_DIRECTORY( )

This attribute defines the local directory to be used as a base path
for LOAD statements.

=item $conn->setConnectionAttr_DEBUG($value)

=item $conn->getConnectionAttr_DEBUG( )

This enables or disable debug messages of the driver. Possible values
are SEDNA_DEBUG_ON and SEDNA_DEBUG_OFF.

=item $conn->setConnectionAttr_CONCURRENCY_TYPE($value)

=item $conn->getConnectionAttr_CONCURRENCY_TYPE( )

This define the nivel of concurrency control applied to this specific
transaction. One of: SEDNA_READONLY_TRANSACTION and
SEDNA_UPDATE_TRANSACTION.

=item $conn->setConnectionAttr_QUERY_EXEC_TIMEOUT($timeout)

=item $conn->getConnectionAttr_QUERY_EXEC_TIMEOUT( )

This defines the number of seconds to wait for an execution.

=item $conn->setConnectionAttr_MAX_RESULT_SIZE($size)

=item $conn->getConnectionAttr_MAX_RESULT_SIZE( )

This controls how much data is allowed to be returned by the server in
bytes.

=item $conn->setConnectionAttr_LOG_AMMOUNT($value)

=item $conn->getConnectionAttr_LOG_AMMOUNT( )

This control how much log the transaction will produce. Values are
SEDNA_LOG_FULL and SEDNA_LOG_LESS.

=item $conn->begin( )

=item $conn->commit( )

=item $conn->rollback( )

This three methods implement the transaction control.

=item $conn->connectionStatus( )

Returns the current connection status.

=item $conn->transactionStatus( )

Returns the current transaction status.

=item $conn->execute($query)

Sends the given query to the server and waits (blocking) for its
return.

=item $conn->executeLong($file)

Sends the query stored in the given file and waits (blockign) for its
return.

=item $conn->next( )

Returns true if there is another value available, and advance the
cursor.

=item $conn->getItem( )

Returns the XML content for the current item in this connection (must
be called after next.

=item $conn->getData($buf, $len)

Works like the read function, storing up to the requested length into
the scalar buffer. Notice that this function will return octets, not
characters, so you should deal with encoding yourself (including
incomplete utf-8 characters).

=item $conn->loadData($xml, $doc, $coll)

Send the xml string to the server for storing using the given document
id and optionally storing in a collection.

=item $conn->endLoadData( )

Send to the server the notice that you finished sending the data.

=back

=head1 SEE ALSO

The development of the bindings is hosted at
http://github.com/ruoso/sedna.  It was based on the quick start guide
at http://www.modis.ispras.ru/sedna/c-samples.html.

=head1 AUTHOR

Daniel Ruoso E<lt>daniel@ruoso.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Daniel Ruoso

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The code for the C driver is embeded into this distribution and is
subject to the Apache License.

=cut
