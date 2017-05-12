package OpenPlugin::Session;

# $Id: Session.pm,v 1.46 2003/04/28 17:43:49 andreychek Exp $

use strict;
use base                  qw( OpenPlugin::Plugin );

$OpenPlugin::Session::VERSION = sprintf("%d.%02d", q$Revision: 1.46 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'session' }

# API

# Returns the session id
sub session_id {
    my ( $self ) = @_;
    return $self->state->{ session_id };
}

# This sub is defined in the individial drivers
sub get_session_data { return undef };

# Initiate a session and return a session_id
sub create {
    my ( $self ) = @_;
    my $session_id;

    my $session = $self->get_session_data();

    $session = $self->_init_session_data( $session, {} );

    if ( $self->_validate_session( $session ) ) {
        $session_id = $session->{_session_id};
    }
    else {
        $session_id = undef;
    }

    untie %{ $session };

    return $session_id;
}

# Retrieve all the values stored within a particular session
sub fetch {
    my ( $self, $session_id ) = @_;
    my $session_vals;

    $session_id = $self->_validate_session_id( $session_id );

    # Don't do anything if we weren't passed a valid session_id
    unless ( $session_id ) {
        $self->OP->log->info( "Invalid session_id given, can't fetch session.");
        return undef;
    }

    my $session = $self->get_session_data( $session_id );

    return undef unless defined $session;

    $session = $self->_init_session_data( $session, {} );

    # Verify that this session is legitimate
    if( $self->_validate_session( $session ) ) {

        $session->{_accessed} = time();

        # Set the session values, then untie the session
        foreach my $key ( keys %{ $session } ) {
            $session_vals->{ $key } = $session->{ $key };
        }
        untie %{ $session };
    }
    else {
        $session_vals = undef;
    }

    return $session_vals;

}

# Save data to a session
sub save {
    my ( $self, $data, $params ) = @_;

    # Make sure we were actually sent some values to save..
    unless ( scalar keys %{ $data } ) {
        $self->OP->log->info( "No session information to be saved." );
        return undef;
    }

    unless ( $params->{'id'}) {
        $params->{'id'} = $self->session_id() || $self->create();
    }

    # Validate the session ID if we were passed one (the ID itself, not the
    # data)
    $params->{'id'} = $self->_validate_session_id( $params->{'id'} ) if
                                                            $params->{'id'};

    # Initiate the session
    my $session = $self->get_session_data( $params->{'id'} );
    $session = $self->_init_session_data( $session, $params );

    # Make sure our session is good
    if ( $self->_validate_session( $session ) ) {

        # Set the session values.  Values starting with _ are readonly for
        # everything but this module
        foreach my $key ( keys %{ $data } ) {
            next if $data->{ $key } =~ m/^_/;

            $session->{ $key } = $data->{ $key };
        }
        $session->{_accessed} = time();

        $self->OP->log->debug( "Saving session ($session->{_session_id}).");
        untie %{ $session };
    }

    return $params->{ id };
}

sub delete {
    my ( $self, $session_id ) = @_;

    unless ( $session_id ) {
        $session_id = $self->session_id();
    }
    my $session = $self->get_session_data( $session_id );

    # Untaint the session_id so it can be properly deleted
    $session_id = $session->{_session_id};
    $session->{_session_id} = $self->_validate_session_id( $session_id );

    tied( %{ $session } )->delete if $session->{_session_id};

    return $session_id;
}

# Set up some values for our session
sub _init_session_data {
    my ( $self, $session, $params ) = @_;

    # When, if at all, the session will expire
    $session->{'_expires'} =
                        $params->{ expires } ||
                        $self->OP->config->{'plugin'}{'session'}{'expires'};

    # If _start exists, we've done this already
    return $session if exists $session->{'_start'};

    $self->OP->log->info( "Initiating session data.");

    # Time the session was created
    $session->{'_start'} = time();

    # Time the session was last accessed
    $session->{'_accessed'} = time();

    return $session;
}

# Validate and untaint the session ID given to us
sub _validate_session_id {
    my ( $self, $session_id ) = @_;

    $session_id ||= "";

    # Does our session ID look legitimate?
    # TODO -- this will only work for MD5 session ID's
    # Apache::Session only supports MD5.  But should something that validates
    #  the session ID string be part of the individual driver instead of here?
    #if( $self->OP->config->{plugin}{session}{parameters}{Generate} eq "MD5" ) {
        if ( $session_id =~ m/^([a-fA-F0-9]{32}$)/ ) {
            return $1;
        }
        else {
            $self->OP->log->info( "The session ID ($session_id) is an " .
                                  "invalid MD5 string.");
            return undef;
        }
    #}
    #else {
    #    $self->OP->log->log(1,  "Not using MD5 sessions, unable to validate " .
    #                            "session id ($session_id).  Continuing "      .
    #                            "anyway...");
    #    return $session_id;
    #}
}

# Validate the properties and expiration of our session
sub _validate_session {
    my ( $self, $session ) = @_;

    my $invalid = 0;

    return undef unless $session;

    # Make sure we have these already..
    $invalid = 1 unless (( exists $session->{_start} )          &&
                         ( exists $session->{_accessed} )       &&
                         ( exists $session->{_session_id} )     &&
                         ( exists $session->{_expires} ));

    # An expiration of -1 means it doesn't expire
    unless ( $session->{_expires} =~ /^-1$/ ) {

        $invalid = 1 if (time >
                    OpenPlugin::Utility->expire_calc( $session->{_expires},
                                                      $session->{_accessed} ));

    }

    if ( $invalid ) {
        $self->OP->log->info( "Session ($session->{_session_id}) is invalid." );

        # Untaint the session_id before we expire it
        $session->{_session_id} = $self->_validate_session_id( $session->{_session_id} );

        tied( %{ $session } )->delete if $session->{_session_id};
        return undef;
    }
    else {
        $self->OP->log->debug( "Session ($session->{_session_id}) is valid." );
        $self->state( 'session_id', $session->{_session_id} );
        return 1;
    }
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Session - Save and retrieve session data

=head1 SYNOPSIS

 my $session = {}
 $session->{camel_humps}     = "one";
 $session->{fish_in_the_sea} = "lots";
 $session->{stooges}         = "three";

 my $session_id = $OP->session->save( $session );

 ...

 my $session = $OP->session->fetch( $session_id );
 print "Humps:   $session->{camel_humps}\n";       # Prints "one"
 print "Fish:    $session->{fish_in_the_sea}\n";   # Prints "lots"
 print "Stooges: $session->{stooges}\n";           # Prints "three"

=head1 DESCRIPTION

Sessions provide a means to save information across requests, for a given user.
Typically, any values created or retrieved for a user are lost after the
request.  With sessions, one can store that data for later retrieval, as long
as the user (or, more specifically, the browser) can later provide the unique
key associated with the data.

=head1 METHODS

B<fetch( $session_id )>

Given a session_id, retrieve an existing session.

Returns a hashref containing all the session data, or undef if the session has
expired.

B<save( \%session_data, [ { id => $id, $expires => $date } ] )>

Save a session.  If a session is already open, the existing session id is used.
If a session id does not yet exist, a new one is created.

Returns the ID of the session saved, or undef on failure.

Basic parameters -- drivers may define others:

=over 4

=item *

B<session_data>: Session data to save.  This should be a reference to a hash.

=item *

B<id> (optional): Session ID to associate with the data being saved.  If not
specified, and you haven't called C<fetch> yet this session, an id will be
randomly chosen for you.  If you have called C<fetch>, the same ID used to
fetch the session will be used to save it.  Usually, you don't need to pass
this in.

=item *

B<expires> (optional): Expiration time, in the format:

 "now"  - expire immediately
 "+180s - in 180 seconds
 "+2m"  - in 2 minutes
 "+12h" - in 12 hours
 "+1d"  - in 1 day
 "+3M"  - in 3 months
 "+2y"  - in 2 years
 "-3m"  - 3 minutes ago(!)

If not specified, the item will have the same expiration time as is listed in
the config file.

=back

B<session_id()>

Returns session ID for the current session. If the session is new or not yet
saved this will return undef.

B<create()>

Create a new session.  It is not necessary to call this function to use
sessions -- fetch and save do the same thing.  This function can be used when
you wish to create a session and get your session id, but aren't ready to save
anything yet.

Returns the ID of the session created.

B<delete( [ $session_id ] )>

Delete an existing session.  If no parameters are passed, it defaults to
deleting the last session opened.  You may pass in a session_id to explicitly
delete a particular session.

Returns the ID of the session deleted if successful.

=head1 BUGS

None known.

=head1 TO DO

The interface for this module is not complete.  Methods for accessing the
sessions creation, modified, and accessed time should be created.  Also one for
finding when it will expire.

I'm also pondering the creation of an OO interface for this module, much like
CGI::Session.  Instead of passing a hashref to the save() function, you'd use
some sort of param() method to save each piece of data.  Maybe.

=head1 SEE ALSO

L<OpenPlugin>

L<Apache::Session|Apache::Session>

L<CGI::Session|CGI::Session>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
