package Rhetoric::Meta;
use common::sense;
use aliased 'Squatting::H';
use Method::Signatures::Simple;
use File::Find::Rule;

# blog metadata and menus will always be in the filesystem
our $meta = H->new({

  pages => method {
    my $base = $self->base;
    my $path = "$base/pages";
    my @pages = 
      map { s/$path\///; s/\.html$//; $_ } 
      File::Find::Rule ->file() ->in($path);
  }

});

1;
