# -*- perl -*-
#
# Copyright (C) 2006-2008 Daniel P. Berrange
#
#
# This program is free software; You can redistribute it and/or modify
# it under the same terms as Perl itself. Either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions of the two licenses.


=pod

=head1 NAME

Net::DBus::GLib - Perl extension for the DBus GLib bindings

=head1 SYNOPSIS

  ####### Attaching to the bus ###########

  use Net::DBus::GLib;

  # Find the most appropriate bus
  my $bus = Net::DBus::GLib->find;

  # ... or explicitly go for the session bus
  my $bus = Net::DBus::GLib->session;

  # .... or explicitly go for the system bus
  my $bus = Net::DBus::GLib->system

=head1 DESCRIPTION

Net::DBus::GLib provides an extension to the Net::DBus module
allowing integration with the GLib mainloop. To integrate with
the main loop, simply get a connection to the bus via the methods
in L<Net::DBus::GLib> rather than the usual L<Net::DBus> module.
That's it - every other API remains the same.

=head1 EXAMPLE

As an example service using the GLib main loop, assuming that
SomeObject inherits from Net::DBus::Service

  my $bus = Net::DBus::GLib->session();
  my $service = $bus->export_service("org.designfu.SampleService");
  my $object = SomeObject->new($service);

  Glib::MainLoop->new()->run();

And as an example client

  my $bus = Net::DBus::GLib->session();

  my $service = $bus->get_service("org.designfu.SampleService");
  my $object = $service->get_object("/SomeObject");

  my $list = $object->HelloWorld("Hello from example-client.pl!");


=head1 METHODS

=over 4

=cut

package Net::DBus::GLib;

use strict;
use warnings;
use Net::DBus;
use Glib;

BEGIN {
    our $VERSION = '0.33.0';
    require XSLoader;
    XSLoader::load('Net::DBus::GLib', $VERSION);
}

=item my $bus = Net::DBus::GLib->find(%params);

Search for the most appropriate bus to connect to and
return a connection to it. For details of the heuristics
used, consult the method of the same name in C<Net::DBus>.
The %params hash may contain an additional entry with a
name of C<context>. This can be a reference to an instance
of the C<Glib::MainContext> object; if omitted, the default
GLib context will be used.

=cut

sub find {
    my $class = shift;
    my %params = @_;
    my $ctx = exists $params{context} ? $params{context} : Glib::MainContext->default;
    delete $params{context};
    my $bus = Net::DBus->find(nomainloop => 1, @_);

    _dbus_connection_setup_with_g_main($bus->get_connection->{connection}, $ctx);

    return $bus;
}

=item my $bus = Net::DBus::GLib->system(%params);

Return a handle for the system message bus. For further
details on this method, consult to the method of the
same name in L<Net::DBus>. The %params hash may contain an
additional entry with a name of C<context>. This can be a
reference to an instance of the C<Glib::MainContext> object;
if omitted, the default GLib context will be used.

=cut

sub system {
    my $self = shift;
    my %params = @_;
    my $ctx = exists $params{context} ? $params{context} : Glib::MainContext->default;
    delete $params{context};
    my $bus = Net::DBus->system(nomainloop => 1, @_);

    _dbus_connection_setup_with_g_main($bus->get_connection->{connection}, $ctx);

    return $bus;
}


=item my $bus = Net::DBus::GLib->session(%params);

Return a handle for the session message bus. For further
details on this method, consult to the method of the
same name in L<Net::DBus>. The %params hash may contain an
additional entry with a name of C<context>. This can be a
reference to an instance of the C<Glib::MainContext> object;
if omitted, the default GLib context will be used.

=cut

sub session {
    my $self = shift;
    my %params = @_;
    my $ctx = exists $params{context} ? $params{context} : Glib::MainContext->default;
    delete $params{context};
    my $bus = Net::DBus->session(nomainloop => 1, @_);

    _dbus_connection_setup_with_g_main($bus->get_connection->{connection}, $ctx);

    return $bus;
}

1;

=pod

=back

=head1 SEE ALSO

L<Net::DBus>, L<Glib>, L<Glib::MainLoop>
C<http://dbus.freedesktop.org>, C<http://gtk.org>

=head1 AUTHOR

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright 2006-2008 by Daniel Berrange

=cut
