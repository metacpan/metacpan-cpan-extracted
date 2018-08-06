package Mojolicious::Plugin::RoutesAuthDBI::Model::Base;
use Mojo::Base 'DBIx::Mojo::Model';

has [qw(app plugin)];

#~ sub new {
  #~ $self = shift->SUPER::new(@_);
#~ }

1;