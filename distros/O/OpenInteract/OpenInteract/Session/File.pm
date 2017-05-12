package OpenInteract::Session::File;

# $Id: File.pm,v 1.3 2002/09/08 20:52:44 lachoy Exp $

use strict;
use base qw( OpenInteract::Session );
use Apache::Session::File;

$OpenInteract::Session::File::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub _create_session {
    my ( $class, $session_id ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;
    my $session_params = $CONFIG->{session_info}{params} || {};
    unless ( $session_params->{Directory} and
             -d $session_params->{Directory} and
             $session_params->{LockDirectory} and
             -d $session_params->{LockDirectory} ) {
        $R->throw({ code => 310, type => 'session',
                    system_msg => "Both the 'Directory' and 'LockDirectory' " .
                                  "keys must be defined under the server " .
                                  "config key 'session_info.params'" });
        $R->scrib( 0, "Error thrown because directories (Dir: ",
                      "[$session_params->{Directory}]) (Lock: ",
                      "[$session_params->{LockDirectory}])" );
        return undef;
    }

    my %session = ();
    $R->DEBUG && $R->scrib( 1, "Trying to fetch session [$session_id]" );
    eval { tie %session, 'Apache::Session::File',
                         $session_id, $session_params };
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

OpenInteract::Session::File - Create sessions within a filesystem

=head1 SYNOPSIS

 # In your configuration file

 [session_info]
 class       = Apache::Session::File
 ...

 [session_info.params]
 Directory     = /home/httpd/oi/sessions/data
 LockDirectory = /home/httpd/oi/sessions/lock
 ...

 [system_alias]
 session       = OpenInteract::Session::File

=head1 DESCRIPTION

Provide a '_create_session' method for
L<OpenInteract::Session|OpenInteract::Session> so we can use a
filesystem as a backend for L<Apache::Session|Apache::Session>.

Note that failure to create the session throws a '310' error, which
clears out the session cookie so it does not keep happening. (See
L<OpenInteract::Error::System|OpenInteract::Error::System> for the
code.)

=head1 METHODS

B<_create_session( $session_id )>

Overrides the method from parent
L<OpenInteract::Session|OpenInteract::Session>, using the
configuration information:

=over 4

=item *

B<session_info.params.Directory> ($)

Specify the directory in which to store sessions. No default is currently
defined.

B<session_info.params.LockDirectory> ($)

Specify the directory in which to store lock information. No default
is currently defined.

=back

=head1 BUGS

None known.

=head1 TO DO

Nothing.

=head1 SEE ALSO

L<Apache::Session::File|Apache::Session::File>

L<OpenInteract::Session|OpenInteract::Session>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
