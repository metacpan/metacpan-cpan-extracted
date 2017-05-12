package OpenPlugin::Param::Apache;

# $Id: Apache.pm,v 1.16 2003/04/03 01:51:25 andreychek Exp $

use strict;
use OpenPlugin::Param();
use base   qw( OpenPlugin::Param );


$OpenPlugin::Param::Apache::VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless $self->OP->request->object;

    # Tell OpenPlugin about each parameter we were sent
    foreach my $field ( $self->OP->request->object->param() ) {
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

OpenPlugin::Param::Apache - Apache driver for the OpenPlugin::Param plugin

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

L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Param|OpenPlugin::Param>
L<Apache|Apache>
L<Apache::Request|Apache::Request>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
