package Teradata::BTET;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into caller's namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Teradata::BTET ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw($activcount
  $errorcode $errormsg) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( $activcount $errorcode $errormsg );
our $VERSION = '0.02';

#sub AUTOLOAD {
#    # This AUTOLOAD is used to 'autoload' constants from the constant()
#    # XS function.  If a constant is not found then control is passed
#    # to the AUTOLOAD in AutoLoader.
#    # We have no constants, so we can just use AutoLoader's.
#
#    goto &AutoLoader::AUTOLOAD;
#}

#-------------------------
#--- PACKAGE VARIABLES
#-------------------------

$Teradata::BTET::msglevel = 1;
$Teradata::BTET::activcount = 0;
$Teradata::BTET::errorcode = 0;
$Teradata::BTET::errormsg = '';

bootstrap Teradata::BTET $VERSION;

#-------------------------
#--- METHODS
#-------------------------

#--- Connect. Returns a connection handle or undef.
sub connect {
 my ($logonstring) = shift;

 my $self = {
    htype => 'conn',  # I am a connection handle.
    logonstring => $logonstring,
 };

 if ( Xconnect($logonstring) ) {
    bless $self, 'Teradata::BTET';
    return $self;
 } else {
    return undef;
 }
}

#--- Disconnect.
sub disconnect {
 my $ch = shift;
 if ($ch->{htype} ne 'conn') {
    Carp::carp "Invalid handle passed to disconnect";
    return 0;
 }

 return Xdisconnect();
}

#--- Prepare a request. Returns a statement handle.
sub prepare {
 my ($ch, $sql, $n) = @_;
 if ($ch->{htype} ne 'conn') {
    Carp::carp "Invalid handle passed to prepare";
    return 0;
 }

#--- n must be 0, 1, or 2.
 $n ||= 0;
 $n = int($n);
 if ($n < 0) { $n = 0; }
 elsif ($n > 2) { $n = 2; }
 else { ; }

 my $self = {
    htype => 'stmt',  # I am a statement handle.
    da => $n,  # SQLDA index
 };

 $sql =~ tr/\n\r/  /;  # Teradata doesn't like newlines.

 if ( Xprepare($sql, $n) ) {
    bless $self, 'Teradata::BTET';
    return $self;
 } else {
    return undef;
 }
}

#--- Execute a request (no data returned).  May have arguments.
sub execute {
 my ($sth, @hvars) = @_;
 my $res = 1;
 if ($sth->{htype} ne 'stmt') {
    Carp::carp "Invalid handle passed to execute";
    return 0;
 }

 return Xexecute($sth->{da}, @hvars);
}

#--- Open a cursor. May have optional input arguments.
sub open {
 my ($sth, @hvars) = @_;
 my $res = 1;
 if ($sth->{htype} ne 'stmt') {
    Carp::carp "Invalid handle passed to open";
    return 0;
 }

 return Xopen($sth->{da}, @hvars);
}

#--- Fetch a row from an open cursor.
sub fetchrow_list {
 my $sth = shift;
 if ($sth->{htype} ne 'stmt') {
    Carp::carp "Invalid handle passed to fetchrow_list";
    return 0;
 }

 return Xfetch($sth->{da}, 0);
}

#--- Fetch a row from an open cursor into a hash.
sub fetchrow_hash {
 my $sth = shift;
 if ($sth->{htype} ne 'stmt') {
    Carp::carp "Invalid handle passed to fetchrow_hash";
    return 0;
 }

 return Xfetch($sth->{da}, 1);
}

#--- Close a cursor.
sub close {
 my $sth = shift;
 my $res = 1;
 if ($sth->{htype} ne 'stmt') {
    Carp::carp "Invalid handle passed to close";
    return 0;
 }

 return Xclose($sth->{da});
}

#--- Begin transaction
sub begin_tran {
 my $ch = shift;
 if ($ch->{htype} ne 'conn') {
    Carp::carp "Invalid handle passed to begin_tran";
    return 0;
 }

 return Xbegin_tran();
}

#--- End transaction
sub end_tran {
 my $ch = shift;
 if ($ch->{htype} ne 'conn') {
    Carp::carp "Invalid handle passed to end_tran";
    return 0;
 }

 return Xend_tran();
}

#--- Abort
sub abort {
 my $ch = shift;
 if ($ch->{htype} ne 'conn') {
    Carp::carp "Invalid handle passed to abort";
    return 0;
 }

 return Xabort();
}

1;
__END__

=head1 Name

Teradata::BTET - Perl interface to Teradata in BTET mode

=head1 Synopsis

  use Teradata::BTET;
  use Teradata::BTET qw(:all);  # Exports variables
  $dbh = Teradata::BTET::connect(logonstring);
  $sth = $dbh->prepare($request [,n]);
  $sth->open();
  $sth->fetchrow_list();
  $sth->close();
  $dbh->disconnect;
  # And others. See below.

=head1 Description

Teradata::BTET is a Perl interface to Teradata SQL. It does not attempt
to be a complete interface to Teradata -- for instance, it does not
allow multiple sessions, asynchronous requests, or PM/API
connections -- but it should be sufficient for many applications.

=head2 Methods

This is an object-oriented module; no methods are exported by default.
The connect method must be called with its full name; other methods
are called with object handles.

Most methods return a true value when they succeed and FALSE upon
failure. The fetch methods, however, return the data to be fetched.
If there is no row to be fetched, they return an empty list.

=over 4

=item B<Teradata::BTET::connect> LOGONSTRING

Connect to Teradata. The argument is a standard Teradata logon string
in the form "[server/]user,password[,'account']". This method returns
a connection handle that must be used for future prepare and disconnect
requests. If the connection fails, undef will be returned. Only one
connection can be active at a time.

=item B<disconnect>

Connection method. Disconnects from Teradata. This method must be
applied to the active connection handle.

=item B<prepare> REQUEST [N]

Connection method. Prepares a request for execution. The first
argument is the SQL request to be prepared. It can be a
multi-statement request, i.e. contain multiple statements
separated by semicolons. The second argument (optional)
is an integer identifying the request; it must be 0, 1, or 2.
The default is 0.
This allows you to have up to three requests active at one time,
each with its own cursor.

prepare returns a request handle or, if the prepare fails,
undef.

The second argument will always be forced to 0, 1, or 2. Consider
this example:

   $st0 = $dbh->prepare("select * from dw.employees", 0);
   $st1 = $dbh->prepare("select * from dw.departments", 1);
   $st2 = $dbh->prepare("select * from dw.assets", 2);
   $st9 = $dbh->prepare("select * from dw.liabilities", 9);

The last statement specifies 9, which is invalid. This value will
be forced to 2, and $st9 will be identical to $st2.

The prepared statement can include parameter markers ('?' in the
place of variables or literals).

=item B<execute> [ARGS]

Statement method. Executes the prepared statement. If the statement
includes parameter markers, arguments can be supplied to take the
place of the markers. For more information, see L<"Data Types">.

This method should be used only when the statement does not return
data. If data is to be returned, use B<open> instead.

=item B<open> [ARGS]

Statement method. Executes the prepared statement and opens a cursor
to contain the results. If the statement
includes parameter markers, arguments can be supplied to take the
place of the markers.

=item B<fetchrow_list>

Statement method. Fetches the next row from the open cursor in list
form; e.g.:

   @row = $sth->fetchrow_list();

=item B<fetchrow_hash>

Statement method. Fetches the next row from the open cursor in hash
form; e.g.:

   %row = $sth->fetchrow_hash();

The hash entries are those specified by PREPARE ... USING NAMES.

=item B<close>

Statement method. Closes the cursor.

=item B<begin_tran>

Connection method. Issues BEGIN TRANSACTION. This statement cannot
be run via B<prepare>.

=item B<end_tran>

Connection method. Issues END TRANSACTION. This statement cannot be
run via B<prepare>.

=item B<abort>

Connection method. Issues ABORT. No arguments are allowed.
This statement cannot be run via B<prepare>.

=back

=head1 Example

  # Connect and get a database handle.
  $dbh = Teradata::BTET::connect("dbc/user,password")
    or die "Could not connect";
  # Prepare a statement; read the results.
  $sth = $dbh->prepare("sel * from edw.employees");
  $sth->open;
  while (@emp_row = $sth->fetchrow_list) {
     print "employee data: @emp_row\n";
  }
  $sth->close;
  $dbh->disconnect;  # Note: $dbh, not $sth.

For more examples, see test.pl.

=head1 Variables

=over 4

=item B<$Teradata::BTET::activcount>

Activity count, i.e. the number of rows affected by the last
SQL operation. This variable can be exported to your namespace.

=item B<$Teradata::BTET::errorcode>

The Teradata error code (I<not> the SQLCODE) from the last SQL
operation. This variable can be exported.

=item B<$Teradata::BTET::errormsg>

The Teradata error message from the last SQL operation. This
variable can be exported.

These three variables can be exported to your namespace all
at once by this means:

   use Teradata::BTET qw(:all);

=item B<$Teradata::BTET::msglevel>

By default, Teradata::BTET will display error codes and messages
from Teradata on stderr. Setting this variable to 0 will suppress
these messages. The default value is 1. The module will honor
changes to the value of this variable at any point during your
program.

=back

=head1 Data Types

Perl uses only three data types: integers, double-precision
floating point, and byte strings.
The data returned from Teradata will be converted to one of
these types and will look like ordinary Perl values.

Dates are returned in either integer form (e.g., 1020815 for
15 August 2002) or in ANSI character form (e.g., '2002-08-15'),
depending on the default for your system, the session
characteristics, and whether you have issued a SET
SESSION DATEFORM request. If you want dates returned in some
other form, you must explicitly cast them, e.g. like this:

   cast(cast(sale_dt as format 'MM/DD/YYYY') as char(10))

By default, times and timestamps are returned as character
strings in their default formats. Again, you can cast them
as you wish in your select statement.

A word of caution is in order about decimal fields.
Decimal fields with a precision of 9 or lower will be
converted to doubles (numeric) and will behave more or less
as expected, with the usual caveats about floating-point
arithmetic. Decimal fields with a higher precision (10-18 digits)
will be converted to character strings. This has the advantage
of preserving their full precision, but it means that Perl
will not treat them as numeric. To convert them to numeric
fields, you can add 0 to them, but values with 16 or more
significant digits will lose precision. You have been warned!

Arguments passed to Teradata via B<open> and B<execute> will be
passed in Perl internal form (integer, double, or byte
string). You can pass undefs to become nulls in the database, but
there are limitations. Since all undefs look the same to the module,
it coerces them all to "integers". This works for most data types,
but Teradata will not allow integer nulls to be placed in BYTE,
TIME, or TIMESTAMP fields. At present, the only workaround for this
situation would be to code a request without parameter
markers and hard-code the nulls to be of the type you want.
In other words, instead of this:

   $sth = $dbh->prepare("insert into funkytown values (?,?,?)");
   $sth->execute(1, "James Brown", undef);

you would code this:

   $sth = $dbh->prepare("insert into funkytown values
      (1, 'James Brown', cast(null as timestamp(0)) )");
   $sth->execute();

=head1 Limitations

The maximum length of a request to be prepared is 65400 bytes.
The maximum length of data to be returned is 65000 bytes.
The maximum number of fields selected or returned by any
statement is 500. Likewise, you can pass no more than 500
arguments to B<open> or B<execute>.

If these limitations are too strict, you can ask your Perl
administrator to change their values in the module's header
file and recompile the module.

The following Teradata features are not supported:

   Partitions other than DBC/SQL (e.g. MONITOR or MLOAD)
   Multiple sessions
   Asynchronous requests
   LOB data types
   CHECKPOINT
   DESCRIBE
   ECHO
   EXECUTE IMMEDIATE
   POSITION
   REWIND

If you would like some features added, write to the author at
the address shown below. No guarantees!

=head1 Author

Geoffrey Rommel, GROMMEL [at] cpan [dot] org.

=cut
