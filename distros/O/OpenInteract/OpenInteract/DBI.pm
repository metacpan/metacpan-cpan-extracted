package OpenInteract::DBI;

# $Id: DBI.pm,v 1.11 2002/05/08 12:02:17 lachoy Exp $

use strict;
use Carp         qw( croak );
use Data::Dumper qw( Dumper );
use DBI          ();

@OpenInteract::DBI::ISA      = qw();
$OpenInteract::DBI::VERSION  = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

use constant DEBUG => 0;

use constant DEFAULT_READ_LEN => 32768;
use constant DEFAULT_TRUNC_OK => 0;

sub connect {
    my ( $class, $db_info, $p ) = @_;
    $p ||= {};

    # Allow callback to modify the connection info; note that we 
    # dereference $db_info for a reason here -- so we don't mess up the 
    # original information, say, in the config hashref

    if ( ref $p->{pre_connect} eq 'CODE' ) {
        DEBUG && _w( 2, "before pre_connect code: ", Dumper( $db_info ) );
        my $new_db_info = $p->{pre_connect}->( \%{ $db_info } );
        $db_info = $new_db_info  if ( $new_db_info->{dsn} );
    }

    # Make the actual connection -- let the 'die' trickle up to our
    # caller if it happens

    my $dsn      = "DBI:$db_info->{driver_name}:$db_info->{dsn}";
    my $username = $db_info->{username};
    my $password = $db_info->{password};
    DEBUG && _w( 2, "Connecting with ($dsn) ($username) ($password)" );
    my $db = eval { DBI->connect( $dsn, $username, $password ) };
    croak "Connect failed: $@\n" if ( $@ );
    DEBUG && _w( 1, "DBI::connect >> Connected ok" );

    # If we have specified a 'db_name', go ahead and 'use' that

    if ( $db_info->{db_name} ) {
        DEBUG && _w( 1, "Use right database ($db_info->{db_name})." );
        my $rv = $db->do( "use $db_info->{db_name}" );
        unless ( $rv ) {
            my $msg = $DBI::errstr;
            $db->disconnect;
            die "Use database failed: $msg\n";
        }
    }

    # We don't set this until here so we can control the format of the
    # error...

    $db->{RaiseError}  = 1;
    $db->{PrintError}  = 0;
    $db->{ChopBlanks}  = 1;
    $db->{AutoCommit}  = 1;
    $db->{LongReadLen} = $db_info->{long_read_len} || DEFAULT_READ_LEN;
    $db->{LongTruncOk} = $db_info->{long_trunc_ok} || DEFAULT_TRUNC_OK;

    $db->trace( $db_info->{trace_level} ) if ( $db_info->{trace_level} );

    # Allow callback to do something with the database handle along with
    # the parameters used to connect to it.

    if ( ref $p->{post_connect} eq 'CODE' ) {
        DEBUG && _w( 1, "Calling post_connect code with handle and info" );
        $p->{post_connect}->( \%{ $db_info }, $db );
    }
    return $db;
}

sub _w {
    return unless ( DEBUG >= shift );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}

1;

__END__

=pod

=head1 NAME

OpenInteract::DBI - Centralized connection location to DBI databases

=head1 SYNOPSIS

 # Get a database handle based on the 'main' info in your config
 # (conf/server.perl)

 my $db = OpenInteract::DBI->connect({ $CONFIG->{db_info}{main} });

=head1 DESCRIPTION

No, we do not subclass DBI with this. No, we do not override any of
the DBI methods. Instead, we provide the means to connect to the
database from one location along with the ability to manipulate the
default connection information before we connect.

For instance, you can setup OpenInteract in two separate
databases. When users of a certain name login (say, 'devel'), you can
change the 'db_name' key of the database connection info hashref from
'webdb' to 'webdb-devel'.

Note that this should work flawlessly with L<Apache::DBI|Apache::DBI>,
and if you are using this on a different persistent Perl platform
(say, PerlEx) then this module gives you a single location from which
to retrieve database handles -- this makes using the BEGIN/END tricks
ActiveState recommends in their FAQ pretty trivial.

=head1 METHODS

B<connect( \%connnect_info, \%params )>

Usage:

 my $connect_name = 'main';
 my $db = eval { OpenInteract::DBI->connect({
                         $CONFIG->{db_info}{ $connect_name } }) };

 die "Cannot connect to database! Error found: $@" if ( $@ );
 my ( $sth );
 eval {
     $sth = $db->prepare( 'SELECT blah FROM bleh' );
     $sth->execute;
 };
 ...

Returns: A DBI database handle with the following parameters set:

 RaiseError:  1
 PrintError:  0
 ChopBlanks:  1
 AutoCommit:  1 (for now...)
 LongReadLen: 32768 (or as set in config)
 LongTruncOk: 0 (or as set in config)

The first parameter is a hashref of connection information. This
should include:

=over 4

=item *

B<dsn> ($)

The last part of a fully-formed DBI data source name used to
connect to this database. Examples:

 Full DBI DSN:     DBI:mysql:webdb
 OpenInteract DSN: webdb

 Full DBI DSN:     DBI:Pg:dbname=web
 OpenInteract DSN: dbname=web

 Full DBI DSN:     DBI:Sybase:server=SYBASE;database=web
 OpenInteract DSN: server=SYBASE;database=web

So the OpenInteract DSN string only includes the database-specific
items for DBI, the third entry in the colon-separated string. This
third item is generally separated by semicolons and usually specifies
a database name, hostname, packet size, protocol version, etc. See
your DBD driver for what to do.

=item *

B<username> ($)

What username should we use to login to this database?

=item *

B<password> ($)

What password should we use in combination with the username to login
to this database?

=item *

B<driver_name> ($)

What DBD driver is used to connect to your database?  (Examples:
'Pg', 'Sybase', 'mysql', 'Oracle')

=item *

B<db_name> ($) (optional)

The name of your database -- only include if you want to 'share
connections' among different websites and if you do not specify the
database name in your B<dsn>.

If you specify this value then this module will try to execute a:

  use $db_name

statement. This will not run in certain databases -- notably
PostgreSQL -- so only include this if you know you need it.

=item *

B<db_owner> ($) (optional)

Who owns this database? Only use if your database uses the database
owner to differentiate different tables.

=item *

B<long_read_len> ($) (optional)

Set the C<LongReadLen> value for the database handle (See L<DBI|DBI>
for information on what this means.) If not set this defaults to
32768.

=item *

B<long_trunc_ok> (bool) (optional)

Set the C<LongTruncOk> value for the database handle (See L<DBI|DBI>
for information on what this means.) If not set this defaults to false.

=item *

B<trace_level> ($) (optional)

Use the L<DBI|DBI> C<trace()> method to output logging information for
all calls on a database handle. Default is '0', which is no
tracing. As documented by L<DBI|DBI>, the levels are:

    0 - Trace disabled.
    1 - Trace DBI method calls returning with results or errors.
    2 - Trace method entry with parameters and returning with results.
    3 - As above, adding some high-level information from the driver
        and some internal information from the DBI.
    4 - As above, adding more detailed information from the driver.
        Also includes DBI mutex information when using threaded Perl.
    5 and above - As above but with more and more obscure information.

=back

The second parameter is also a hashref and can contain the following
keys:

=over 4

=item *

B<pre_connect> (\&) (optional)

The coderef stored here is called before the database handle is
requested, allowing you to modify any of the information in the first
parameter before it is sent to DBI.

Takes the hashref of database connection info as its first parameter,
and it B<must> return a hashref of database connection info with the
same conventions as the one passed in. Failure to do so means the
changes are discarded.

=item *

B<post_connect> (\&) (optional)

The coderef stored here is called after the database handle is
requested and allows you to perform whatever actions on it that you
like.

Takes the hashref of database connection info as its first parameter
and the newly created database handle as its second parameter.

There currently is no return value for this callback -- primarily
because I am not sure what it might be used for :-) Suggestions
welcome!

=back

Any errors encountered will result in an exception thrown via
C<die>. Generally, there will be two errors:

=over 4

=item *

B<Connect error>: This means you cannot even connect to the
database. This is generally a very serious error.

You can distinguish this by doing a match on the returned error string
for C</^Connect failed:/>. Everything after this string is the actual
error reported by DBI.

=item *

B<Use database error>: This means you connected to the database
server, but were not able to 'use' your database. (If your database
does not support the 'use' command, please contact the author.) If you
get this error you might want to investigate specifying your database
name in the 'dsn' paramter and not specifying a database name in the
'db_name' parameter.

You can find this error by matching the returned error string on
C</^Use database failed: />. Everything after this string is the
actual error reported by DBI.

=back

Other errors may occur in your callbacks, but reporting them is
entirely up to you. This class does not wrap the call in an C<eval {}>
block so you can capture the error and inspect it yourself. After all,
they B<are> your callbacks.

=head1 STRATEGIES

Under mod_perl, you can use the simple connection-pooling module
L<Apache::DBI|Apache::DBI>. This module is quite simple -- it
overrides the C<connect> call for L<DBI|DBI>. For each C<connect> call
made, it looks at the parameters (dsn, username, password and the DBI
parameters) to determine whether it has connected to this database
previously. If so, it returns the cached connection. If not, it
creates the connection and caches it. This happens on a
per-httpd-child basis, so if you have 10 httpd children you will have
10 concurrent connections to the database. Easy, right?

What happens if you are running multiple websites using one httpd
child? Say you have five websites running on mod_perl process group
which has the aforementioned 10 children. Since each website likely
has its own database, you will eventually have C<10 x 5 = 50>
connections to your database. This can be a bad thing.

To get around this, and assuming that all of these websites connect to
the database as the same user (which certainly is not a given),
OpenInteract allows you to specify a single database for
connection. Once the connection is handed out, OpenInteract will
perform the SQL 'use' command to switch to the correct database.

The trigger for this is the 'db_name' key of the first parameter
passed into the C<connect> method of this class. If this field is
specified, the method will perform the following statement:

 $dbh->do( "use $db_info->{db_name}" );

So that you only have to keep one connection for this database open
all the time.

=head1 TO DO

B<Test with PerlEx>

Try to use the BEGIN/END tricks ActiveState recommends -- do they work
with just scripts, or also with modules?

=head1 BUGS

None known.

=head1 SEE ALSO

L<Apache::DBI|Apache::DBI>

L<DBI|DBI> - http://www.symbolstone.org/technology/perl/DBI

PerlEx - http://www.activestate.com/Products/PerlEx/

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

Marcus Baker <mbaker@intes.net>

=cut
