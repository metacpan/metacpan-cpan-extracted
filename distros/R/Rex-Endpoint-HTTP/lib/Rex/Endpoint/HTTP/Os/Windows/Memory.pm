package Rex::Endpoint::HTTP::Os::Windows::Memory;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Win32::API;

use Rex::Endpoint::HTTP::Interface::System;

sub free {
   my $self = shift;
   my $memory_info = $self->_iface->get_memory_statistics;
   $self->render_json({ok => Mojo::JSON->true, free => $memory_info->{avail_memory}});
}

sub max {
   my $self = shift;
   my $memory_info = $self->_iface->get_memory_statistics;
   $self->render_json({ok => Mojo::JSON->true, max => $memory_info->{total_memory}});
}

sub used {
   my $self = shift;
   my $memory_info = $self->_iface->get_memory_statistics;
   $self->render_json({ok => Mojo::JSON->true, used => $memory_info->{total_memory} - $memory_info->{avail_memory}});
}

sub _iface {
   my ($self) = @_;
   return Rex::Endpoint::HTTP::Interface::System->create;
}

1;
