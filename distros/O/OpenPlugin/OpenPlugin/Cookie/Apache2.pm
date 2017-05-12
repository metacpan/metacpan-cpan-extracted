package OpenPlugin::Cookie::Apache2;

# $Id: Apache2.pm,v 1.3 2003/05/06 03:33:06 andreychek Exp $

use strict;
use OpenPlugin::Cookie();
use base                    qw( OpenPlugin::Cookie );
use Apache::Cookie();
use Data::Dumper            qw( Dumper );

$OpenPlugin::Cookie::Apache2::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless $self->OP->request->object;

    my $cookies = Apache::Cookie->fetch;

    # Tell OpenPlugin about each cookie we were sent
    foreach my $cookie ( keys %{ $cookies } ) {

        $self->set_incoming({ name    => $cookies->{$cookie}->name,
                              value   => $cookies->{$cookie}->value,
                              domain  => $cookies->{$cookie}->domain,
                              path    => $cookies->{$cookie}->path,
                              expires => $cookies->{$cookie}->expires,
                              secure  => $cookies->{$cookie}->secure,
                           });
    }

    return $self;
}


# Cycle through the Apache::Cookie objects and
# call the bake method, which puts the appropriate header
# into the outgoing headers table.

sub bake {
    my ( $self ) = @_;

    foreach my $name ( $self->get_outgoing ) {

        my $args = $self->get_outgoing( $name );
        $args->{name} = $name;

        Apache::Cookie->new( $self->OP->request->object,
                                        -name     => $args->{name},
                                        -value    => $args->{value},
                                        -path     => $args->{path},
                                        -expires  => $args->{expires},
                                        -secure   => $args->{secure},
                    )->bake;
    }

return 1;
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Cookies::Apache - Apache driver for the OpenPlugin::Cookie plugin

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

=head1 TO DO

Nothing.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Apache|Apache>
L<Apache::Cookie|Apache::Cookie>
L<Apache::Request|Apache::Request>
L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Cookie|OpenPlugin::Cookie>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
