package OpenPlugin::Upload::Apache2;

# $Id: Apache2.pm,v 1.3 2003/08/28 19:19:33 andreychek Exp $

use strict;
use OpenPlugin::Upload();
use base   qw( OpenPlugin::Upload );

$OpenPlugin::Upload::Apache2::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless $self->OP->request->object;

    #foreach my $upload ( $self->OP->request->object->upload() ) {
    #    $self->set_incoming({
    #        name         => $upload->name,
    #        content_type => $upload->type,
    #        size         => $upload->size,
    #        filehandle   => $upload->fh,
    #        filename     => $upload->filename,
    #    });
    #}

    return $self;
}

1;

=pod

=head1 NAME

OpenPlugin::Upload::Apache - Apache driver for the OpenPlugin::Upload plugin

=head1 NOTE

The Apache2 Upload plugin does not work as expected, and should not be used.
It will be working soon.

=head1 PARAMETERS

This plugin is a child of the L<Request|OpenPlugin::Request> plugin.  Without
the Request plugin, this one cannot function properly.  That being the case,
you won't actually pass in parameters to this plugin, but to the request
plugin.  See the L<Request|OpenPlugin::Request> plugin for more information.

=head1 CONFIG OPTIONS

=over 4

=item * driver

Apache

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

L<Apache|Apache>
L<Apache::Request|Apache::Request>
L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Upload|OpenPlugin::Upload>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
