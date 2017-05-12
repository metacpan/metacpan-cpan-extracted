package OpenInteract::Session;

# $Id: Session.pm,v 1.13 2003/01/08 05:21:33 lachoy Exp $

use strict;
use Data::Dumper qw( Dumper );

$OpenInteract::Session::VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

$OpenInteract::Session::COOKIE_NAME = 'session';

sub parse {
    my ( $class, $session_id ) = @_;
    my $R     = OpenInteract::Request->instance;
    $session_id ||= $R->{cookie}{in}{ $OpenInteract::Session::COOKIE_NAME };

    # If no session id, just create an empty hashref; when we go to 
    # save it, we check to see if the hashref is tied and if not,
    # create a new session

    unless ( $session_id ) {
        $R->DEBUG && $R->scrib( 1, "No session_id found. Skipping session_init..." );
        $R->{session} = {};
        return undef;
    }
    $R->{session} = $class->_create_session( $session_id );
    unless ( $R->{session} ) {
        $R->{session} = {};
        return undef;
    }
    $R->DEBUG && $R->scrib( 2, "Retrieved session properly: ", Dumper( $R->{session} ) );

    # Check to see if we should expire the session

    unless ( $class->is_session_valid ) {
        $R->DEBUG && $R->scrib( 1, "Session is expired; clearing out." );
        eval { tied( %{ $R->{session} } )->delete() };
        if ( $@ ) {
            $R->scrib( 0, "Caught error trying to remove expired session: $@\n",
                          "Continuing without problem since this just means",
                          "you'll have a stale session in your datastore" );
        }
        $R->{session} = {};
        return undef;
    }

    return 1;
}


sub is_session_valid {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    return 1 unless ( $R->{session}{timestamp} );
    my $expires_in = $R->CONFIG->{session_info}{expires_in};
    return 1 unless ( $expires_in > 0 );
    my $last_refresh = ( time - $R->{session}{timestamp} ) / 60;
    return 1 unless ( $last_refresh > $expires_in );
    $R->DEBUG && $R->scrib( 1, "Session has expired. Last refresh was ",
                               "[", sprintf( '%5.2f', $last_refresh ) , "] minutes ago at ",
                               "[", scalar localtime( $R->{session}{timestamp} ) , "]",
                               "and threshold is [", $expires_in, "] minutes" );
    return undef;
}


sub save {
    my ( $class ) = @_;
    my $R = OpenInteract::Request->instance;
    my $CONFIG = $R->CONFIG;

    if ( tied %{ $R->{session} } ) {
        $R->{session}{timestamp} = $R->{time};
        $R->DEBUG && $R->scrib( 2, "Saving tied session\n", Dumper( $R->{session} ) );
        untie %{ $R->{session} };
    }
    elsif ( ref( $R->{session} ) ) {
        $R->DEBUG && $R->scrib( 1, "Session not yet created. Creating..." );
        unless ( scalar keys %{ $R->{session} } ) {
            $R->DEBUG && $R->scrib( 1, "No session information saved. Exiting..." );
            return 1;
        }
        my $session = $class->_create_session;
        if ( $session ) {

            # Set the expiration. If the key 'expiration' is defined
            # then use that, even if the value in the session is blank
            # or undef. This allows you to set sessions that expire
            # when the browser is closed when a user requests (see
            # OpenInteract::Auth).

            my ( $expiration );
            if ( exists $R->{session}{expiration} ) {
                $expiration = $R->{session}{expiration};
                $R->DEBUG && $R->scrib( 1, "Expiration for new session manually set to ($expiration)" );
                delete $R->{session}{expiration};
            }
            else {
                $expiration = $CONFIG->{session_info}{expiration};
                $R->DEBUG && $R->scrib( 1, "Expiration for new session set to default from config ($expiration)" );
            }

            # Set the session values

            foreach my $key ( keys %{ $R->{session} } ) {
                $session->{ $key } = $R->{session}{ $key };
            }

            $session->{timestamp} = $R->{time};
            $R->cookies->create_cookie({ name    => $OpenInteract::Session::COOKIE_NAME,
                                         value   => $session->{_session_id},
                                         path    => '/',
                                         expires => $expiration });
            $R->DEBUG && $R->scrib( 2, "Saving new session\n", Dumper( $session ) );
            untie %{ $session };
        }
        else {
            $R->scrib( 0, "Could not create session! See error log." );
        }
    }
    return 1;
}

sub _create_session { return undef }

1;

__END__

=head1 NAME

OpenInteract::Session - Implement session handling in the framework

=head1 SYNOPSIS

 # In OpenInteract.pm Note that $R->session translates to
 # OpenInteract::Session::Blah thanks to the server configuration key
 # 'system_alias::session'

 $R->session->parse;

 # Access the data the session from any handler

 $R->{session}{my_stateful_data} = "oogle boogle";
 $R->{session}{favorite_colors}{red} += 5;

 # And from any template you can use the OI template plugin (see
 # OpenInteract::Template::Plugin)

 <p>The weight of your favorite colors are:
 [% FOREACH color = keys OI.session.favorite_colors %]
   * [% color %] -- [% OI.session.favorite_colors.color %]
 [% END %]

 # in the main content handler, OpenInteract.pm
 # Only call once you're done accessing the data

 $R->session->save;

=head1 DESCRIPTION

Sessions are a fundamental part of OpenInteract, and therefore session
handling is fairly transparent. We rely on
L<Apache::Session|Apache::Session> to do the heavy-lifting for us.

This handler has two public methods: C<parse()> and C<save()>. Guess in which
order they are meant to be called?

This class also requires you to implement a subclass that overrides
the _create_session method with one that returns a valid
L<Apache::Session|Apache::Session> tied hashref. OpenInteract provides
L<OpenInteract::Session::DBI|OpenInteract::Session::DBI> for DBI
databases,
L<OpenInteract::Session::SQLite|OpenInteract::Session::SQLite> for
SQLite databases, and ,
L<OpenInteract::Session::File|OpenInteract::Session::File> using the
filesystem. Implementations using other media are left as an exercise
for the reader.

Subclasses should refer to the package variable
C<$OpenInteract::Session::COOKIE_NAME> for the name of the cookie to
create, and should throw a '310' error of type 'session' if unable to
connect to the session data source to create a session.

You can create sessions that will expire if not used by setting the
C<session_info.expires_in> server configuration key. See the
description below in L<CONFIGURATION> for more information.

=head1 METHODS

B<parse()>

Get the session_id and fetch a session for this user; if one does not
exist, just set the {session} property of C<$R> to an anonymous
hashref. If data exist when we want to save it, we will create a
session form it then. Otherwise we will not bother.

B<save()>

Save the session off for later. If we did not initially create one do
so now if there is information in {session}.

=head1 CONFIGURATION

The following configuration keys are used:

=over 4

=item *

B<session_info.expiration> (optional)

Used to set the time a session lasts. See L<CGI|CGI> for an explanation of
the relative date strings accepted.

=item *

B<session_info.expires_in> (optional)

Used to set the time (in number of minutes) greater than which a
session will expire due to inactivity.

=back

=head1 TO DO

Nothing

=head1 BUGS

None known.

=head1 SEE ALSO

L<Apache::Session|Apache::Session>

L<OpenInteract::Template::Plugin|OpenInteract::Template::Plugin>:
makes the session hash information available to the template

C<OpenInteract::Cookies::*> -- routines for parsing, creating, setting
cookie information so we can match up users with session information

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>
