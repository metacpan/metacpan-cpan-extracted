package Net::Rendezvous::Publish::Service;
use strict;
use warnings;
use base qw( Class::Accessor::Lvalue );
__PACKAGE__->mk_accessors(qw( _session _handle name type port domain published ));

=head1 NAME

  Net::Rendezvous::Publish::Service - a Rendezvous odvertised service

=head1 SYNOPSIS

  use Net::Rendezvous::Publish;
  my $z = Net::Rendezvous::Publish->new;
  # publish a webserver on an odd port
  my $service = $z->publish( name => "My Webserver",
                             type => "_http._tcp",
                             port => 8231 );
  # handle callbacks for 10 seconds
  for (1..100) { $z->step( 0.1 ) }

  # stop publishing the service
  $service->stop;

=head1 DESCRIPTION

A Net::Rendezvous::Publish::Service represents a service you tried to
publish.

You never create one directly, and instead are handed one by the
publish method.

=head1 METHODS

=head2 stop

Stop advertising the service.

=cut

sub stop {
    my $self = shift;
    $self->_session->_backend->publish_stop( $self->_handle );
    $self->published = 0;
}

sub _publish_callback {
    my $self = shift;
    my $result = shift;
    $self->published = $result eq 'success' ? 1 : 0;
}

1;

__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Net::Rendezvous::Publish - the module this module supports

=cut

