package Net::Rendezvous::Publish;
use strict;
use warnings;
use Net::Rendezvous::Publish::Service;

use Module::Pluggable
  search_path => [ "Net::Rendezvous::Publish::Backend" ],
  sub_name    => 'backends';

use base qw( Class::Accessor::Lvalue );
__PACKAGE__->mk_accessors(qw( _backend _published ));

our $VERSION = 0.04;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new;

    my ($backend) = $args{backend} || (grep !/::Null$/, $self->backends)[0];
    $backend ||= "Net::Rendezvous::Publish::Backend::Null";

    eval "require $backend" or die $@;
    return unless $backend;
    $self->_backend = $backend->new
      or return;
    $self->_published = [];
    return $self;
}

sub publish {
    my $self = shift;
    my $service = Net::Rendezvous::Publish::Service->new;
    $service->_session = $self;
    $service->_handle  = $self->_backend->publish( object => $service, @_ )
      or return;
    return $service;
}

sub step {
    my $self = shift;
    $self->_backend->step( shift );
    return $self;
}


1;

__END__

=head1 NAME

Net::Rendezvous::Publish - publish Rendezvous services

=head1 SYNOPSIS

 use Net::Rendezvous::Publish;
 my $publisher = Net::Rendezvous::Publish->new
   or die "couldn't make a Responder object";
 my $service = $publisher->publish(
     name => "My HTTP Server",
     type => '_http._tcp',
     port => 12345,
 );
 while (1) { $publisher->step( 0.01 ) }

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Creates a new publisher handle

=head2 publish( %definition )

Returns a Net::Rendezvous::Publish::Service object.  The following
keys are meaningful in the service definition hash.

=over

=item name

A descriptive name for the service.

=item type

The type of service.  This is string of the form _service._protocol.

=item port

The port on which you're advertising the service.  If you're not using
a port (and instead just using mDNS as a way of propogating other
service information) it's common practice to use 9 (the discard
service)

=item domain

The domain in which to advertise a service.  Defaults to C<local.>

=back

=head2 step( $seconds )

Spend at most $seconds seconds handling network events and updating
internal state.

=head TODO

At some point I may learn enough of the mDNS protocol to write a
pure-perl responder.  That'll be nifty.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, 2005, 2006, Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::Rendezous> - for service browsing.

L<Net::Rendezvous::Publish::Backend::*> - you'll need one of these to talk
to your local mDNS responder.

=cut
