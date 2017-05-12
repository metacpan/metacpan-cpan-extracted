package OpenPlugin::HttpHeader::Apache2;

# $Id: Apache2.pm,v 1.4 2003/08/12 00:51:51 andreychek Exp $

use strict;
use OpenPlugin::HttpHeader();
use base          qw( OpenPlugin::HttpHeader );

$OpenPlugin::HttpHeader::Apache2::VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

# This driver will only work if used under mod_perl

sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless ( $self->OP->request->object );

    # Tell OpenPlugin about each header we were sent
    foreach my $header (keys %{ $self->OP->request->object->headers_in() }) {
        $self->set_incoming( $header,
                $self->OP->request->object->headers_in->{ $header });
    }

    return $self;
}

*send = \*send_outgoing;

sub send_outgoing {
    my ( $self, $type ) = @_;

    $type ||= 'text/html';
    foreach my $name ( $self->get_outgoing ) {
        $self->OP->request->object->headers_out->{ $name } =
                                                $self->get_outgoing( $name );
    }

    # If the cookie plugin is loaded, check to see if we need to send any
    # cookies along with the header
    $self->OP->cookie->bake if grep /^cookie$/, $self->OP->loaded_plugins;

    $self->OP->request->object->content_type( $type );

    # Something, which has to be nothing, needs to be returned!  Not having a
    # return statement causes the value of the last line to be returned, which
    # in this case, is 1 (true), which ends up being printed on the top of
    # every website and is a pain in the butt to troubleshoot.  Returning undef
    # causes a bunch of undefined variable messages
    return "";
}

1;

__END__

=pod

=head1 NAME

OpenPlugin::HttpHeader::Apache2 - Apache2 driver for the OpenPlugin::HttpHeader
plugin

=head1 PARAMETERS

This plugin is a child of the L<Request|OpenPlugin::Request> plugin.  Without
the Request plugin, this one cannot function properly.  That being the case,
you won't actually pass in parameters to this plugin, but to the request
plugin.  See the L<Request|OpenPlugin::Request> plugin for more information.

=head1 CONFIG OPTIONS

=over 4

=item * driver

Apache2

As this is a child plugin of the Request plugin, the configuration of this
plugin should be embedded within the configuration for the Request plugin.
Additionally, if you wish to use this driver for this plugin, then you must
also enable this driver under the Request plugin.

=back

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
