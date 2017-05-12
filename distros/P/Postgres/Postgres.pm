#!/usr/local/bin/perl
package Postgres;

use strict;
use vars qw($VERSION @ISA @EXPORT $error);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     db_connect
);
$VERSION = 0.0 + substr(q$Revision: 1.4 $, 10);

require 5.002;

bootstrap Postgres $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Postgres - Perl interface to the Postgres95 SQL database engine

=head1 SYNOPSIS

 use Postgres;

 $conn = db_connect($database,$host,$port)
   or die "could not connect -- $Postgres::error";

 The parameters $host and $port are optional (or may be undef).
 This will use the default Postgres95 values for them.

 print "Connected Database: ", $conn->db();
 print "Connected Host: ", $conn->host();
 print "Connection Options: ", $conn->options();
 print "Connected Port: ", $conn->port();
 print "Connected tty: ", $conn->tty();
 print "Connection Error Message: ", $conn->errorMessage();

This method is identical to PQreset(conn)

 $conn->reset();

This method executes an SQL statement or query.

 $query = $conn->execute($sql_statement)
   or die "Error -- $Postgres::error";

Retrieve the values from a SELECT query.

 @array = $query->fetchrow();

Get information from the results of the last query.

 $val = $query->cmdStatus();
 $val = $query->oidStatus();

Calling the following functions on a result handle that is not from a
SELECT is undefined.

 $val = $query->ntuples();
 $val = $query->nfields();
 $val = $query->fname($column_index);
 $val = $query->fnumber($column_name);
 $val = $query->ftype($column_index);
 $val = $query->fsize($column_index);

These functions are provided for completeness but are not intended to be
used.  The fetchrow() method will return C<undef> for a field which is null.

 $val = $query->getvalue($tuple_index,$column_index);
 $val = $query->getlength($tuple_index,$column_index);
 $val = $query->getisnull($tuple_index,$column_index);

The putline() and getline() functions are called as follows:

 $query->putline($string);
 $value = $query->getline();
 $query->endcopy();

=head1 DESCRIPTION

This package is designed as close as possible to its C API
counterpart, but be more like Perl in how you interact with the API.
The C Programmer Guide that comes with Postgres describes most things
you need.

The following functions are currently not implemented: PQtrace(),
PQendtrace(), and the asynchronous notification.  I do not believe
that binary cursors will work, either.

Once you db_connect() to a database, you can then issue commands to
the execute() method.  If either of them returns an error from the
underlying API, the value returned will be C<undef> and the variable
C<$Postgres::error> will contain the error message from the database.
The C<$port> parameter to db_connect() is optional and will use the
default port if not specified.  All environment variables used by the
PQsetdb() function are honored.

The method fetchrow() returns an array of the values from the next row
fetched from the server.  It returns an empty list when there is no
more data available.  Fields which have a NULL value return C<undef>
as their value in the array.  Calling fetchrow() or the other
tuple-related functions on a statement handle which is B<not> from a
SELECT statement has undefined behavior, and may well crash your
program.  Other functions work identically to their similarly-named C
API functions.

=head2 No finish or clear statements

Whenever the scalar that holds the statement or connection handle
loses its value, the underlying data structures will be freed and
appropriate connections closed.  This can be accomplished by
performing one of these actions:

=over 4

=item undef the handle

=item use the handle for another purpose

=item let the handle run out of scope

=item exit the program.

=back

=head2 Error messages

A global variable C<$Postgres::error> always holds the last error
message.  It is never reset except on the next error.  The only time
it holds a valid message is after execute() or db_connect() returns
C<undef>.

=head1 PREREQUISITES

You need to have the Postgres95 database server installed and
configured on your system to use this module.

Be sure to set the proper directory locations in the C<Makefile.PL>
file for your installation.

=head1 AUTHOR

Vivek Khera (C<vivek@khera.org>).  Many ideas were taken from the
MsqlPerl module.  I am no longer maintaining this module.  If you
would like to take over, please let me know.

=cut
