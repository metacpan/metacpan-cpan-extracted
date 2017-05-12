package OpenInteract::Session::DBI;

# $Id: DBI.pm,v 1.10 2002/09/08 20:52:44 lachoy Exp $

use strict;
use base qw( OpenInteract::Session );

$OpenInteract::Session::DBI::VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

sub _create_session {
    my ( $class, $session_id ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;
    my $session_class  = $CONFIG->{session_info}{class};
    my $session_params = $CONFIG->{session_info}{params} || {};
    my $datasource     = $CONFIG->{session_info}{datasource} ||
                         $CONFIG->{datasource}{default_connection_db};
    $session_params->{Handle} = $R->db( $datasource );

    # Detect Apache::Session::MySQL and modify parameters
    # appropriately

    if ( $session_class =~ /MySQL$/ ) {
        $session_params->{LockHandle} = $session_params->{Handle};
        $R->DEBUG && $R->scrib( 2, "Using MySQL session store, with LockHandle parameter" );
    }
    my %session = ();
    $R->DEBUG && $R->scrib( 1, "Trying to fetch session [$session_id]" );
    eval { tie %session, $session_class, $session_id, $session_params };
    if ( $@ ) {
        $R->throw({ code       => 310,
                    type       => 'session',
                    system_msg => $@,
                    extra      => { class      => $session_class,
                                    session_id => $session_id } });
        $R->scrib( 0, "Error thrown. Now clear the cookie" );
        return undef;
    }

    # Only return the session if it's not empty
    return \%session if ( scalar keys %session );
    return undef;
}

1;

__END__

=head1 NAME

OpenInteract::Session::DBI - Create sessions within a DBI data source

=head1 SYNOPSIS

 # In your configuration file

 [session_info]
 class       = Apache::Session::MySQL
 ...

 [system_alias]
 session       = OpenInteract::Session::DBI

 # Use a different datasource

 [db_info session_storage]
 db_owner      =
 username      = webuser
 password      = s3kr1t
 dsn           = dbname=sessions
 db_name       =
 driver_name   = Pg
 sql_install   =
 long_read_len = 65536
 long_trunc_ok = 0

 [session_info]
 class       = Apache::Session::Postgres
 datasource  = session_storage
 ...

 [system_alias]
 session       = OpenInteract::Session::DBI

=head1 DESCRIPTION

Provide a '_create_session' method for
L<OpenInteract::Session|OpenInteract::Session> so we can use a DBI
data source as a backend for L<Apache::Session|Apache::Session>.

Note that failure to create the session throws a '310' error, which
clears out the session cookie so it does not keep happening. (See
L<OpenInteract::Error::System> for the code.)

Note that former users of C<OpenInteract::Session::MySQL> (now
defunct) should have no problems using this class -- just specify the
'session_class' as L<Apache::Session::MySQL|Apache::Session::MySQL>
and everything should work smoothly.

If you want to use SQLite as a backend, see
L<OpenInteract::Session::SQLite|OpenInteract::Session::SQLite>.

=head1 METHODS

B<_create_session( $session_id )>

Overrides the method from parent
L<OpenInteract::Session|OpenInteract::Session> to take a session ID
and retrieve a session from the datastore. We use the following
configuration information:

=over 4

=item *

B<session_info.class> ($)

Specify the session serialization implementation class -- e.g.,
L<Apache::Session::MySQL|Apache::Session::MySQL>,
L<Apache::Session::Postgres|Apache::Session::Postgres>, etc.

=item *

B<session_info.datasource> ($) (optional)

Use a datasource different from that specified in
'datasource.default_connection_db'.

=item *

B<session_info.params> (\%) (optional)

Parameters that get passed directly to the session serialization
implementation class. These depend on the implementation.

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing.

=head1 SEE ALSO

L<Apache::Session|Apache::Session>

L<OpenInteract::Session|OpenInteract::Session>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
