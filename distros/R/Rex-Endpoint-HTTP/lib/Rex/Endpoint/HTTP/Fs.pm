package Rex::Endpoint::HTTP::Fs;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Mojo::Upload;
use Data::Dumper;
use MIME::Base64;

use Rex::Endpoint::HTTP::Interface::Fs;

# This action will render a template
sub ls {
   my $self = shift;

   eval {
      my @ret = $self->_iface->ls($self->_path);
      $self->render_json({ok => Mojo::JSON->true, ls => \@ret});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub is_dir {
   my $self = shift;

   if($self->_iface->is_dir($self->_path)) {
      $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      $self->render_json({ok => Mojo::JSON->false});
   }
}

sub is_file {
   my $self = shift;

   if($self->_iface->is_file($self->_path)) {
      $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      $self->render_json({ok => Mojo::JSON->false});
   }
}

sub unlink {
   my $self = shift;

   eval {
      $self->_iface->unlink($self->_path);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub mkdir {
   my $self = shift;

   eval {
      $self->_iface->mkdir($self->_path);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub stat {
   my $self = shift;

   eval {
      my $ret = $self->_iface->stat($self->_path);
      $self->render_json({ok => Mojo::JSON->true, stat => $ret});
   } or do {
      $self->render_json({ok => Mojo::JSON->false}, status => 404);
   };
}

sub is_readable {
   my $self = shift;

   if($self->_iface->is_readable($self->_path)) {
      $self->render_json({ok => Mojo::JSON->true});
   }

   $self->render_json({ok => Mojo::JSON->false});
}

sub is_writable {
   my $self = shift;

   if($self->_iface->is_writable($self->_path)) {
      $self->render_json({ok => Mojo::JSON->true, is_writable => Mojo::JSON->true});
   }
}

sub readlink {
   my $self = shift;

   eval {
      $self->render_json({ok => Mojo::JSON->true, link => $self->_iface->readlink($self->_path)});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };

}

sub rename {
   my $self = shift;

   eval {
      my $ref = $self->req->json;
      my $old = $ref->{old};
      my $new = $ref->{new};

      $self->_iface->rename($old, $new);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };

}

sub glob {
   my $self = shift;

   my @glob = $self->_iface->glob($self->req->json->{"glob"});
   $self->render_json({ok => Mojo::JSON->true, glob => \@glob});
}

sub upload {
   my $self = shift;

   eval {
      my $path = $self->req->param("path");
      my $upload = $self->req->upload("content");

      $self->_iface->upload($path, $upload);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };

}

sub download {
   my $self = shift;

   eval {
      my $content = $self->_iface->download($self->_path);
      $self->render_json({
         ok => Mojo::JSON->true,
         content => encode_base64($content),
      });
   } or do {
      $self->render_json({ok => Mojo::JSON->false}, status => 404);
   };
}

sub ln {
   my $self = shift;

   eval {
      my $ref = $self->req->json;
      $self->_iface->ln($ref->{from}, $ref->{to});
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub rmdir {
   my $self = shift;

   eval {
      $self->_iface->rmdir($self->_path);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub chown {
   my $self = shift;

   my $ref = $self->req->json;

   my $user = $ref->{user};
   my $file = $self->_path;
   my $options = $ref->{options};

   eval {
      $self->_iface->chown($user, $file, $options);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub chgrp {
   my $self = shift;

   my $ref = $self->req->json;
   my $group = $ref->{group};
   my $file = $self->_path;

   my $options = $ref->{options};

   eval {
      $self->_iface->chgrp($group, $file, $options);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub chmod {
   my $self = shift;

   my $ref = $self->req->json;
   my $mode = $ref->{mode};
   my $file = $self->_path;
   my $options = $ref->{options};

   eval {
      $self->_iface->chmod($mode, $file, $options);
      $self->render_json({ok => Mojo::JSON->true});
   } or do {
      $self->render_json({ok => Mojo::JSON->false});
   };
}

sub cp {
   my $self = shift;

   my $ref = $self->req->json;

   my $source = $ref->{source};
   my $dest   = $ref->{dest};

   eval {
      $self->_iface->cp($source, $dest);
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
   return Rex::Endpoint::HTTP::Interface::Fs->create;
}


1;
