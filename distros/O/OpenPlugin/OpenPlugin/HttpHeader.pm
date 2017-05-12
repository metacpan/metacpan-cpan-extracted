package OpenPlugin::HttpHeader;

# $Id: HttpHeader.pm,v 1.21 2003/04/03 01:51:24 andreychek Exp $

use strict;

@OpenPlugin::HttpHeader::ISA     = qw( OpenPlugin::Plugin );
$OpenPlugin::HttpHeader::VERSION = sprintf("%d.%02d", q$Revision: 1.21 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'httpheader' }


*get = \*get_incoming;

# Retrieve a list of headers sent from the browser to us
sub get_incoming {
    my ( $self, $name ) = @_;

    unless ( $name ) {
        return keys %{ $self->state->{incoming} };
    }

    return $self->state->{ incoming }{ $name } || undef;
}

# Tell OpenPlugin about the headers we've been sent
sub set_incoming {
    my ( $self, $name, $value ) = @_;
    return undef if ( $name eq "Cookie" );
    return undef unless ( $name ) && ( defined($value) );
    $self->state->{ incoming }{ $name } = $value;
}

# Display headers in the outgoing headers queue
sub get_outgoing {
    my ( $self, $name ) = @_;

    unless ( $name ) {
        return keys %{ $self->state->{ outgoing } };
    }

    return $self->state->{ outgoing }{ $name } || undef;
}

*set = \*set_outgoing;

# Save a header to the outgoing queue
sub set_outgoing {
    my ( $self, $name, $value ) = @_;
    return undef unless ( $name );

    # If the headers were passed in as a reference to a hash
    if( ref $name eq "HASH" ) {
        while( my( $key, $val ) = each %{ $name } ) {
            $self->_set_outgoing( $key, $val );
        }
    }
    else {
        $self->_set_outgoing( $name, $value );
    }
}

# Called by set_outgoing, tells OpenPlugin to add a header to the outgoing queue
sub _set_outgoing {
    my ( $self, $name, $value ) = @_;

    # Remove a header from the outgoing queue
    if (( $name ) && ( !defined $value )) {
        delete $self->{_m}{OP}{_state}{HttpHeader}{outgoing}{ $name };
        return;
    }

    return $self->state->{ outgoing }{ $name } = $value;
}

sub send_outgoing {}

1;

__END__

=pod

=head1 NAME

OpenPlugin::HttpHeader - Represent the incoming and outgoing HTTP headers for a request

=head1 SYNOPSIS

 @incoming_headers = $OP->httpheader->get_incoming();

 $header_value = $OP->httpheader->get_incoming( 'Content-Type' );

 $OP->httpheader->set_outgoing({ 'foo' => 'bar });

 $OP->httpheader->send_outgoing();

=head1 DESCRIPTION

The HttpHeader plugin offers an interface to retrieve headers sent from the
browser to the server, and to send headers back to the browser.

=head1 METHODS

B<set_incoming( $name => $value )>

Sets all incoming parameters. This is normally called only by the particular
Header driver, and not by an application.

B<get_incoming( [ $name ] )>

B<get( [ $name ] )>

Called by itself, get_incoming returns a list of header names which the browser
sent to us during the last request.

Called with the optional name parameter, get_incoming returns the value for
that particular header.

B<set_outgoing( $key => $value )>

B<set( $key => $value )>

Set C<$key> to C<$value>.

To clear an outgoing header value, use C<undef> for the value:

 $header->set_outgoing( 'Content-Type', undef );

B<get_outgoing()>

Returns a list of outgoing keys and values. A value may be an
arrayref. (SEE ABOVE)

B<send_outgoing()>

B<send()>

Sends the outgoing HTTP headers.

This function checks to see if there are any cookies to be sent whenever it is
called.

=head1 BUGS

None known.

=head1 TO DO

See the TO DO section of the <OpenPlugin::Request> plugin.

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
