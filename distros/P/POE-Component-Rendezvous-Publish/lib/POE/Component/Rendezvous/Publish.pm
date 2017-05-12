package POE::Component::Rendezvous::Publish;

use strict;
use warnings;

our $VERSION = '0.01';

use Net::Rendezvous::Publish;
use POE;
use POE::Session;


sub create {
  my $class = shift;

  my $publisher = Net::Rendezvous::Publish->new;
  return undef unless $publisher;

  my $self = bless { publisher => $publisher, services => {} }, $class;
  $self->add_service( @_ );
  
  POE::Session->create(
      object_states => [
        $self => {
          _start => '_start_event',
          step   => '_step_event',
        },
      ],
  );
}


sub _start_event {
  my $self = $_[OBJECT];
  my $kern = $_[KERNEL];

  $kern->delay_set( step => 2 );
}


sub _step_event {
  my $self = $_[OBJECT];
  my $kern = $_[KERNEL];

  $kern->delay_set( step => 2 );
  $self->step();
}


sub step {
  my $self = shift;
  my $pub  = $self->{publisher};

  $pub->step( 0.01 );
}


sub add_service {
  my $self = shift;
  my $pub  = $self->{publisher};
  my %args = @_;

  return 0 unless $args{name};
  
  my $service = $pub->publish( %args ); 
  return 0 unless $service;

  $self->{$args{name}} = $service;
  return 1;
}


1;
__END__
=head1 NAME

POE::Component::Rendezvous::Publish - publish Rendevouz services from POE

=head1 SYNOPSIS

  use POE qw(Component::Rendezvous::Publish);

  POE::Component::Rendevouz::Publish->create(
      name   => 'My POE-based service',
      type   => '_service._protocol',
      port   => 12345,
      domain => 'local.',
  );


=head1 DESCRIPTION

POE::Component::Rendezvous::Publish makes your network-oriented
POE-based services available via Rendezvous browsing.

If your POE-based service has a Web interface, you can publish a service
via Rendezvous, and all the Rendezvous-enabler browsers will see it.

POE::Component::Rendezvous::Publish uses L<Net::Rendezvous::Publish> to
do the actual work. Check it's documentation to see which mDNS systems
are supported. As of March 2005, it supported Apple and Howl.


=head1 Constructor Parameters

=over 2

=item name

A descriptive name for the service.

=item type

The type of service. This is a string of the form
_service._protocol.

=item port

The port on which you're advertising the service.

=item domain

The domain in which we advertise a service. Defaults to "local.".


=head1 EXAMPLE

A simple HTTP server published via Rendezvous would look like this:

    use POE qw( Component::Rendezvous::Publish Component::Server::HTTP );
    use HTTP::Status;


    my $port = $ENV{HTTP_PORT} || 8787;

    my $http = POE::Component::Server::HTTP->new(
      Port => $port,
      ContentHandler => {
          '/' => \&respond,
      },
      Headers => {
        Server => 'My Rendezvous-aware HTTP server',
      },
    );


    my $publish = POE::Component::Rendezvous::Publish->create(
      name => 'simple http server',
      type => '_http._tcp',
      port => $port,
    );


    $poe_kernel->run;


    sub respond {
      my ($request, $response) = @_;

      $response->code(RC_OK);
      $response->content("Yelllow, you fetched " . $request->uri);
      
      return RC_OK;
    }


=head1 TODO

Support stop publishing a service (given it's name).

Allow publish of several services using the same
PoCo::Rendezvous::Publish session.

Right now, we pool each 2 seconds to see if there are network messages
pending to be replied. The pooling is limited to 0.01 seconds.

I'm trying to see how we can get a file descriptor from the modules
below, so that we can use POE internal Wheels to warn us when there is
traffic to be dealt with, thus improving the efficienty of this module.

We don't have any tests either.

=head1 SEE ALSO

L<POE>, L<Net::Rendezvous::Publish>, L<Net::Rendezvous::Publish::Backend::Apple>,
L<Net::Rendezvous::Publish::Backend::Howl>


=head1 ACKNOWLEDGMENTS

Parts of this documentation where stolen^Hcopied from
L<Net::Rendezvous::Publish> documentation by Richard Clamp.


=head1 AUTHOR

Pedro Melo, E<lt>melo@cpan.org<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Pedro Melo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
