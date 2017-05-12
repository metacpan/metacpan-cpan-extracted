package OpenPlugin::Cookie::CGI;

# $Id: CGI.pm,v 1.21 2003/04/03 01:51:24 andreychek Exp $

use strict;
use OpenPlugin::Cookie();
use base        qw( OpenPlugin::Cookie );
use CGI         qw( -no_debug );
use CGI::Cookie qw();

$OpenPlugin::Cookie::CGI::VERSION = sprintf("%d.%02d", q$Revision: 1.21 $ =~ /(\d+)\.(\d+)/);


sub init {
    my ( $self, $args ) = @_;

    return $self unless $self->OP->request->object;

    my $cookies = CGI::Cookie->fetch;

    # Tell OpenPlugin about each cookie we were sent
    foreach my $cookie ( keys %{ $cookies } ) {

        $self->set_incoming({ name    => $cookies->{$cookie}->name,
                              value   => $cookies->{$cookie}->value,
                              domain  => $cookies->{$cookie}->domain,
                              path    => $cookies->{$cookie}->path,
                              expires => $cookies->{$cookie}->expires,
                              secure  => $cookies->{$cookie}->secure,
                           })
    }

    return $self;
}

# Cycle through the CGI::Cookie objects and
# call the bake method, which puts the appropriate header
# into the outgoing headers table.

sub bake {
    my ( $self ) = @_;

    foreach my $name ( $self->get_outgoing ) {

        my $args = $self->get_outgoing( $name );
        $args->{name} = $name;

        my $cookie = CGI::Cookie->new( -name     => $args->{name},
                                       -value    => $args->{value},
                                       -path     => $args->{path},
                                       -expires  => $args->{expires},
                                       -secure   => $args->{secure},
                    );
        print "Set-Cookie: $cookie\n";
    }

return 1;
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Cookie::CGI - CGI driver for the OpenPlugin::Cookie plugin

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

=head1 SEE ALSO

L<CGI|CGI>
L<CGI::Cookie|CGI::Cookie>
L<OpenPlugin|OpenPlugin>
L<OpenPlugin::Cookie|OpenPlugin::Cookie>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut

