package Rex::Endpoint::HTTP::File;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use MIME::Base64;

use Rex::Endpoint::HTTP::Interface::File;

sub open {
   my $self = shift;

   my $ref = $self->req->json;

   eval {
      $self->_iface->open($ref->{mode}, $self->_path);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };

}

sub read {
   my $self = shift;

   my $ref = $self->req->json;
   
   my $file = $self->_path;
   my $start = $ref->{start};
   my $len = $ref->{len};

   eval {
      my $buf = $self->_iface->read($file, $start, $len);
      $self->render_json({ok => Mojo::JSON->true, buf => encode_base64($buf)});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };

}

# this seems odd, but "write" is not allowed as an action
sub write_fh {
   my $self = shift;

   my $ref = $self->req->json;

   my $file = $self->_path;
   my $start = $ref->{start};
   my $buf = decode_base64($ref->{buf});

   eval {
      my $bytes_written = $self->_iface->write_fh($file, $start, $buf);
      $self->render_json({ok => Mojo::JSON->true, bytes_written => $bytes_written});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub seek {
   my $self = shift;

   eval {
      $self->_iface->seek;
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub close {
   my $self = shift;

   eval {
      $self->_iface->close;
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub _path {
   my $self = shift;
   
   my $ref = $self->req->json;
   return $ref->{path};
}

sub _iface {
   my ($self) = @_;
   return Rex::Endpoint::HTTP::Interface::File->create;
}

1;
