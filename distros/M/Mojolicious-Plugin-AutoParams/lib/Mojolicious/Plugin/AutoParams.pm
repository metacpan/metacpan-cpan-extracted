package Mojolicious::Plugin::AutoParams;
use Mojo::Base 'Mojolicious::Plugin';
use strict;
use warnings;

our $VERSION = '0.02';

sub register {
    my ($self,$app,$config) = @_;

    $app->hook(around_action => sub {
              my ($next, $c, $action, $last) = @_;
              my $endpoint = $c->match->endpoint;
              return $c->$action unless ref $endpoint eq 'Mojolicious::Routes::Route';
              my @placeholders = @{ $endpoint->pattern->placeholders };
              my @params;
              my %params;
              for my $level ( @{ $c->match->stack }) {
                  my $placeholder = shift @placeholders or last;
                  while ($placeholder and exists( $level->{$placeholder} ) ) {
                      push @params, $level->{$placeholder};
                      $params{$placeholder} = $level->{$placeholder};
                      $placeholder = shift @placeholders;
                  }
              }
              return $c->$action(@params) unless $config->{named};
              return $c->$action(%params) if $config->{named} eq '1';
              if ($config->{named} eq '_') {
                  local $_ = \%params;
                  return $c->$action;
              }
              return $c->$action;
     });
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AutoParams - Send captured placeholder values as parameters for routes.

=head1 SYNOPSIS

     use Mojolicious::Lite;
     use experimental 'signatures';
     plugin 'auto_params';

     get '/hello/:name' => sub ($c,$name) { $c->render(text => "hi, $name") }

OR

     use Mojolicious::Lite;
     plugin 'auto_params', { named => 1 }

     get '/hello/:name' => sub {
             my $c = shift;
             my %args = @_;
             $c->render(text => "hi, $args{name}")
     };

OR

     use Mojolicious::Lite;
     plugin 'auto_params', { named => '_' }

     get '/hello/:name' => sub { shift->render(text => "hi, $_->{name}") }

=head1 DESCRIPTION

This module automatically sends placeholders as a list of parameters to routes.

By default it uses positional parameters, but it will optionally send a hash if
the "named" option is set to 1.

Setting 'named' to '_' will set the local $_ to a hashref of the placeholders.

=head1 AUTHOR

Brian Duggan <bduggan@matatu.org>

=cut


