package Mojolicious::Plugin::SpectreCss;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::File 'path';

our $VERSION = '0.01';

sub register {
  my ($self, $app) = @_;

  my $asset = path(__FILE__)->sibling('SpectreCss')->child('asset');
  push @{$app->static->paths}, $asset->child('public')->to_string;
}

1;
