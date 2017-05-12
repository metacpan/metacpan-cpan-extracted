package OpenInteract::Session::SQLite;

# $Id: SQLite.pm,v 1.3 2002/09/08 20:52:43 lachoy Exp $

use strict;
use base qw( OpenInteract::Session );
use Apache::Session::SQLite;

$OpenInteract::Session::DBI::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub _create_session {
    my ( $class, $session_id ) = @_;
    my $R = OpenInteract::Request->instance;
    my $dbname = $R->CONFIG->{session_info}{params}{dbname};
    unless ( $dbname ) {
        $R->throw({ code => 310, type => 'session',
                    system_msg => "Cannot use SQLite session storage without " .
                                  "the parameter 'dbname' defined to a valid " .
                                  "SQLite file" });
        $R->scrib( 0, "No definition for SQLite file in 'session_info.params.dbname'" );
        return undef;
    }
    my %session = ();
    $R->DEBUG && $R->scrib( 1, "Trying to fetch session [$session_id] with db [$dbname]" );
    eval { tie %session, 'Apache::Session::SQLite',
                         $session_id,
                         { DataSource => "DBI:SQLite:dbname=$dbname" } };
    if ( $@ ) {
        $R->throw({ code       => 310,
                    type       => 'session',
                    system_msg => $@,
                    extra      => { session_id => $session_id } });
        $R->scrib( 0, "Error thrown. Now clear the cookie" );
        return undef;
    }
    return \%session if ( scalar keys %session );
    return undef;
}

1;


__END__

=head1 NAME

OpenInteract::Session::SQLite - Create sessions within a SQLite data source

=head1 SYNOPSIS

 # In your configuration file

 [session_info]
 class       = Apache::Session::SQLite
 ...

 [session_info.params]
 dbname = /home/httpd/oi/conf/sqlite_sessions
 ...

 [system_alias]
 session       = OpenInteract::Session::SQLite

=head1 DESCRIPTION

Provide a '_create_session' method for
L<OpenInteract::Session|OpenInteract::Session> so we can use a SQLite
data source as a backend for
L<Apache::Session::SQLite|Apache::Session::SQLite>.

Note that failure to create the session throws a '310' error, which
clears out the session cookie so it does not keep happening. (See
L<OpenInteract::Error::System> for the code.)

This code is fairly untested under normal server loads. I do not know
what the behavior of SQLite is with many concurrent reads and writes
-- you might want to read the SQLite documentation about modifying the
attributes of the data file so that every write is not synchronized
with the filesystem.

=head1 METHODS

B<_create_session( $session_id )>

Overrides the method from parent
L<OpenInteract::Session|OpenInteract::Session>, serializing sessions
to and from a file named in the configuration, as specified
below. This file should have the following table defined:

 CREATE TABLE sessions (
   id char(32) not null,
   a_session text,
   primary key( id )
 )

=over 4

=item *

B<session_info.params.dbname> ($)

Specify the file used for serializing sessions. It should already have
the 'sessions' table defined.

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing.

=head1 SEE ALSO

L<Apache::Session::SQLite|Apache::Session::SQLite>

L<OpenInteract::Session|OpenInteract::Session>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
