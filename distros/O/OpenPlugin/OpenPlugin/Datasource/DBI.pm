package OpenPlugin::Datasource::DBI;

# $Id: DBI.pm,v 1.18 2003/04/03 02:47:31 andreychek Exp $

use strict;
use Data::Dumper  qw( Dumper );
use DBI           qw();

@OpenPlugin::Datasource::DBI::ISA      = qw();
$OpenPlugin::Datasource::DBI::VERSION  = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

use constant DEFAULT_READ_LEN => 32768;
use constant DEFAULT_TRUNC_OK => 0;

sub connect {
    my ( $class, $OP, $ds_name, $ds_info ) = @_;

    unless ( ref $ds_info ) {
       $OP->exception->throw( "Cannot create connection without ",
                              "datasource info!" );
    }

    unless ( $ds_name ) {
        $OP->log->warn( 'WARNING: Correct usage of connect() is',
               '$self->connect( $ds_name, \%ds_info ). Will continue...' );
    }

    unless ( $ds_info->{'driver'} ) {
        $OP->exception->throw("Value for 'driver' must be defined in ",
                              "datasource [$ds_name]." );
    }

    # Make the connection -- let the 'die' trickle up to our caller if
    # it happens

    my $dsn      = "DBI:$ds_info->{driver}:$ds_info->{dsn}";
    my $username = $ds_info->{'username'};
    my $password = $ds_info->{'password'};

    if( $OP->log->is_info ) {
        $OP->log->info( "Trying to connect to DBI with information:\n",
                               Dumper( $dsn ) );
    }

    my $dbh = eval { DBI->connect( $dsn, $username, $password ); };

    if( $@ or not $dbh ) {
        $OP->exception->throw( "Database connect error: $DBI::errstr" );
    }

    $OP->log->info( "DBI connection made ok" );

    # We don't set this until here so we can control the format of the
    # error...

    $dbh->{'RaiseError'}  = 1;
    $dbh->{'PrintError'}  = 0;
    $dbh->{'ChopBlanks'}  = 1;
    $dbh->{'AutoCommit'}  = 1;
    $dbh->{'LongReadLen'} = $ds_info->{'long_read_len'} || DEFAULT_READ_LEN;
    $dbh->{'LongTruncOk'} = $ds_info->{'long_trunc_ok'} || DEFAULT_TRUNC_OK;

    $dbh->trace( $ds_info->{'trace_level'} ) if ( $ds_info->{'trace_level'} );

    return $dbh;
}


sub disconnect {
    my ( $class, $OP, $handle ) = @_;
    eval { $handle->disconnect };
    $OP->exception->throw( $@ ) if ( $@ );
    return 1;
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Datasource::DBI - DBI driver, used to create DBI database handles
for the OpenPlugin::Datasource plugin

=head1 SYNOPSIS

 # Define the parameters for a database handle 'main' in the config file

 <datasource main>
    type          = DBI
    db_owner      =
    username      = webuser
    password      = urkelnut
    dsn           = host=localhost;database=urkelweb
    db_name       =
    driver        = mysql
    long_read_len = 65536
    long_trunc_ok = 0
 </datasource>

 # Request the datasource 'main':

 my $dbh = $OP->datasource->connect( 'main' );
 my $sth = $dbh->prepare( "SELECT * FROM urkel_fan" );
 $sth->execute;
 ...

=head1 DESCRIPTION

No, we do not subclass DBI with this. No, we do not override any of
the DBI methods. Instead, we provide the means to connect to the
database from one location using nothing more than a datasource
name. This is somewhat how the Java Naming and Directory Interface
(JNDI) allows you to manage objects, including database connections.

Note that if you are using it this should work flawlessly with
L<Apache::DBI|Apache::DBI>, and if you are using this on a different
persistent Perl platform (say, PerlEx) then this module gives you a
single location from which to retrieve database handles -- this makes
using the BEGIN/END tricks ActiveState recommends in their FAQ pretty
trivial.

=head1 METHODS

B<connect( $datasource_name, \%datasource_info )>

Returns: A DBI database handle with the following parameters set:

 RaiseError:  1
 PrintError:  0
 ChopBlanks:  1
 AutoCommit:  1 (for now...)
 LongReadLen: 32768 (or as set in \%datasource_info)
 LongTruncOk: 0 (or as set in \%datasource_info)

The parameter C<\%datasource_info> defines how we connect to the
database.

=over 4

=item *

B<dsn> ($)

The last part of a fully-formed DBI data source name used to
connect to this database. Examples:

 Full DBI DSN:     DBI:mysql:webdb
 OpenPlugin DSN:   webdb

 Full DBI DSN:     DBI:Pg:dbname=web
 OpenPlugin DSN:   dbname=web

 Full DBI DSN:     DBI:Sybase:server=SYBASE;database=web
 OpenPlugin DSN:   server=SYBASE;database=web

So the OpenPlugin DSN string only includes the database-specific items
for DBI, the third entry in the colon-separated string. This third
item is generally separated by semicolons and usually specifies a
database name, hostname, packet size, protocol version, etc. See your
DBD driver for what to do.

=item *

B<driver> ($)

What DBD driver is used to connect to your database?  (Examples:
'Pg', 'Sybase', 'mysql', 'Oracle')

=item *

B<db_name> ($) (optional)

TODO: Will we keep this? Unsure...

The name of your database -- only include if you want to 'share
connections' among different websites and if you do not specify the
database name in your B<dsn>.

=item *

B<db_owner> ($) (optional)

Who owns this database? Only use if your database uses the database
owner to differentiate different tables.

=item *

B<username> ($)

What username should we use to login to this database?

=item *

B<password> ($)

What password should we use in combination with the username to login
to this database?

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

Any errors encountered will cause an exception to be thrown.  The error message
will generally be a connection error, meaning you cannot even connect to the
database. This is generally a very serious error.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Apache::DBI|Apache::DBI>

L<DBI|DBI> - http://www.symbolstone.org/technology/perl/DBI

PerlEx - http://www.activestate.com/Products/PerlEx/

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

Chris Winters <chris@cwinters.com>

=cut
