package OpenPlugin::HttpHeader::CGI;

# $Id: CGI.pm,v 1.24 2003/04/03 01:51:25 andreychek Exp $

use strict;
use OpenPlugin::HttpHeader();
use base   qw( OpenPlugin::HttpHeader );
use CGI( -no_debug );

$OpenPlugin::Params::CGI::VERSION = sprintf("%d.%02d", q$Revision: 1.24 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    return $self unless $self->OP->request->object;

    my @headers;

    { # The HTTP sub in CGI.pm can produce some odd looking warnings
        local $^W = 0;
        @headers = $self->OP->request->object->http();
    }
    # Tell OpenPlugin about each header we were sent
    foreach my $header ( @headers ){
        $self->set_incoming( $header,
                $self->OP->request->object->http( $header ));
    }

    return $self;
}

*send = \*send_outgoing;

sub send_outgoing {
    my ( $self, $type ) = @_;

    $type ||= "text/html";
    $self->set_outgoing( "-content_type", $type );

    print $self->OP->request->object->header( $self->get_outgoing );

    # If the cookie plugin is loaded, check to see if we need to send any
    # cookies along with the header
    $self->OP->cookie->bake if
                    grep "OpenPlugin::Cookie", $self->OP->loaded_plugins;


    return undef;
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::HttpHeader::CGI - CGI Driver for the OpenPlugin::HttpHeader plugin

=head1 PARAMETERS

This plugin is a child of the L<Request|OpenPlugin::Request> plugin.  Without
the Request plugin, this one cannot function properly.  That being the case,
you won't actually pass in parameters to this plugin, but to the request
plugin.  See the L<Request|OpenPlugin::Request> plugin for more information.

=head1 CONFIG OPTIONS

=over 4

=item * driver

CGI

As this is a child plugin of the Request plugin, the configuration of this
plugin should be embedded within the configuration for the Request plugin.
Additionally, if you wish to use this driver for this plugin, then you must
also enable this driver under the Request plugin.

=back

=head1 METHODS

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
