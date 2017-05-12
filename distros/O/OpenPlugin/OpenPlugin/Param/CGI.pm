package OpenPlugin::Param::CGI;

# $Id: CGI.pm,v 1.18 2003/04/03 01:51:25 andreychek Exp $

use strict;
use OpenPlugin::Param();
use base   qw( OpenPlugin::Param );
use CGI    qw( -no_debug );

$OpenPlugin::Param::CGI::VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    return $self unless $self->OP->request->object;

    # Tell OpenPlugin about each parameter we were sent
    foreach my $field ( $self->OP->request->object->param() ) {

        # Don't show uploads in this plugin
        next if ( $self->OP->request->object->upload( $field ));

        my @values = $self->OP->request->object->param( $field );
        if ( scalar @values > 1 ) {
            $self->set_incoming( $field, \@values );
        }
        else {
            $self->set_incoming( $field, $values[0] );
        }
    }

    return $self;
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Param::CGI - CGI driver for the OpenPlugin::Param plugin

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

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

OpenPlugin, OpenPlugin::Param, CGI

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
