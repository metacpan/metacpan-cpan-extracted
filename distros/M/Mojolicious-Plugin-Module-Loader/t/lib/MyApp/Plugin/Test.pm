package MyApp::Plugin::Test;
use v5.26;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use experimental qw(signatures);

sub register($self, $app, $conf) {
  warn("MyApp::Plugin::Test Loaded\n");
}

1;
