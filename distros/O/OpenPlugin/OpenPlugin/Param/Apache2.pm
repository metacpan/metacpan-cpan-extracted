package OpenPlugin::Param::Apache2;

# $Id: Apache2.pm,v 1.3 2003/08/12 00:51:51 andreychek Exp $

use strict;
use OpenPlugin::Param();
use base   qw( OpenPlugin::Param );


$OpenPlugin::Param::Apache2::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

sub init {
    my ( $self, $args ) = @_;

    # This is here for now because when compiling this module at Apache startup
    # time, we don't have an Apache::Request object yet.  We should find a
    # better way to do this though.
    return $self unless $self->OP->request->object;

    my %params = $self->parse_args( $self->OP->request->object->args() );

    # Tell OpenPlugin about each parameter we were sent
    while ( my ( $field, $value ) = each %params ) {

        $self->set_incoming( $field, $value );
    }

    return $self;
}

# This sub is taken from Apache 2's Apache::compat.  It'll keep up from having
# to load that module, as this is all we need from it.  It simply takes the
# query string, and parses it out into a list
sub parse_args {
    my ( $self, $string ) = @_;
    return () unless defined $string and $string;

    return map {
        s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
        $_;
    } split /[=&;]/, $string, -1;

}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Param::Apache2 - Apache2 driver for the OpenPlugin::Param plugin

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
