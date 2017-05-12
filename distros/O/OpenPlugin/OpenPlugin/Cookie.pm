package OpenPlugin::Cookie;

# $Id: Cookie.pm,v 1.25 2003/04/03 01:51:23 andreychek Exp $

use strict;
use base                    qw( OpenPlugin::Plugin );
use Data::Dumper            qw( Dumper );

$OpenPlugin::Cookie::VERSION = sprintf("%d.%02d", q$Revision: 1.25 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'cookie' }

# Tell OpenPlugin about the cookies we've been sent
sub set_incoming {
    my ( $self, $cookie ) = @_;

    return undef unless ( $cookie->{name} );

    $cookie->{value}     ||= "";
    $cookie->{domain}    ||= "";
    $cookie->{path}      ||= "";
    $cookie->{expires}   ||= "";
    $cookie->{secure}    ||= "";

    return $self->state->{ incoming }{ $cookie->{name} } = {
                                            value   => $cookie->{value},
                                            domain  => $cookie->{domain},
                                            path    => $cookie->{path},
                                            expires => $cookie->{expires},
                                            secure  => $cookie->{secure},
                                        };
}

*get = \*get_incoming;

# Retrieve cookies sent from the browser
sub get_incoming {
    my ( $self, $name ) = @_;

    # Just return a list of cookies
    unless ( $name ) {
        return keys %{ $self->state->{ incoming } };
    }

    # Return a single cookie as a hash
    return $self->state->{ incoming }{ $name };
}

# Display cookies in the outgoing cookies queue
sub get_outgoing {
    my ( $self, $name ) = @_;

     unless ( $name ) {
         return keys %{ $self->state->{ outgoing } };
     }

    return $self->state->{ outgoing }{ $name } || undef;

}

*set = \*set_outgoing;

# Save a cookie to the outgoing queue
sub set_outgoing {
    my ( $self, $args ) = @_;

    if( ref $args eq "HASH" ) {
        my @keys = keys %{ $args };

        # The cookie(s) were sent in as a hash of hashes
        if ( ref $args->{ $keys[0] } eq "HASH" ) {
            foreach my $key ( @keys ) {
                my $cookie = $args->{ $key };
                $cookie->{ name } = $key;
                $self->_set_outgoing( $cookie );
            }
        }

        # We were sent a single cookie as a hash
        else {
            $self->_set_outgoing( $args );
        }
    }

    # The cookies were sent in as an array of hashes
    elsif( ref $args eq "ARRAY" ) {
        foreach my $cookie ( @{ $args } ) {
            $self->_set_outgoing( $cookie );
        }
    }
    else {
        $self->OP->log->warn( "Unknown format used in attempt to create " .
                               "a cookie!" );
    }

    return 1;
}

# Called by set_outgoing, tells OpenPlugin to add a cookie to the outgoing
# queue
sub _set_outgoing {
    my ( $self, $args ) = @_;

    # Remove a cookie from the outgoing queue
    if (( $args->{ name } ) && ( !exists $args->{ value } )) {
        delete $self->{_m}{OP}{_state}{Cookie}{outgoing}{$args->{ name }};
        return;
    }

    $args->{path}    ||= "/";
    $args->{expires} ||= "";
    $args->{domain}  ||= "";
    $args->{secure}  ||= 0;

    return $self->state->{ outgoing }{ $args->{name} } = {
                                        value    => $args->{value},
                                        path     => $args->{path},
                                        expires  => $args->{expires},
                                        domain   => $args->{domain},
                                        secure   => $args->{secure},
                                    };
}

# These functions are defined in the individual drivers
sub init { }
sub bake { }


1;

__END__

=pod

=head1 NAME

OpenPlugin::Cookie - handler to parse/output cookies from/to the client

=head1 SYNOPSIS

 # Retrieve the cookies from the client request

 $OP->cookies->get_incoming;

 # Create a new cookie

 $OP->cookies->set_outgoing({
                        name    => 'search_value',
                        expires => '+3M',
                        value   => 'this AND that',
                    });

 # Expire an old cookie

 $OP->cookies->set_outgoing({
                        name    => 'search_value',
                        expires => '-3d',
                        value   => undef,
                     });

 # The cookies are sent to the browser upon sending the HTTP Header

 $OP->httpheader->send_outgoing();

=head1 DESCRIPTION

This module defines methods for retrieving and creating
cookies.  You can find information regarding cookies at the following url:

 http://www.ics.uci.edu/pub/ietf/http/rfc2109.txt

=head1 METHODS

B<set_outgoing( \%params )>

B<set( \%params )>

This method creates a cookie, which will be sent to the browser at the same
time the headers are sent.  Pass in normal parameters (see below) and the
function will create a cookie for you.

Parameters:

=over 4

=item * name (required)

Name of cookie

=item * value (required)

Value of cookie

=item * expires (optional)

When the cookie expires ( '+3d', etc.). Note that negative values (e.g., '-3d'
will expire the cookie on most browsers. Leaving this value empty or undefined
will create a 'short-lived' cookie, meaning it will expire when the user closes
their browser.

The following are examples of valid expiration times:

 "now"  - expire immediately
 "+180s - in 180 seconds
 "+2m"  - in 2 minutes
 "+12h" - in 12 hours
 "+1d"  - in 1 day
 "+3M"  - in 3 months
 "+2y"  - in 2 years
 "-3m"  - 3 minutes ago(!)

=item * path (optional)

Path it responds to.

Lets say, for example, that you choose a path "C</cgi-bin>".  The browser will
only send the cookie back to the server if the url path the browser is calling
includes C</cgi-bin>.

=back

B<get_incoming( [ $cookie_name ] )>

B<get( [ $cookie_name ] )>

Called with no parameters, C<get_incoming()> returns a list containing the
names of each cookie sent to the server.

Called with one parameter, get_incoming returns a reference to a hash
containing the values/parameters for C<$cookie_name>.  See C<get_incoming> for
a list of the parameters this function returns.

B<set_incoming( \%params )>

Typically called internally by the Cookie driver to tell OpenPlugin about the
cookies which we were sent.  If for some reason you wish to alter cookie
information that has already been sent to the server, you can do so with this
function.

See the C<set_outgoing> function for valid parameters for C<\%params>.

=head1 TO DO

See the TO DO section of the <OpenPlugin::Request> plugin.

=head1 BUGS

Oddly, expiring of cookies does not seem to work yet.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
