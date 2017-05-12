package Mojolicious::Plugin::TypeModel;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app, $conf) = @_;
  my $base = $conf->{base};
  my $types = $base->types;

  # model aliases
  for my $type (keys %$types) {
    $app->helper("model.$type" => sub { shift; $base->model($type => @_) });
  }
}

1;

