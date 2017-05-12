use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

package A::User;

sub new { bless {}, shift }

package main;

plugin 'MoreUtilHelpers';

get '/count_single' => sub {
  my $self = shift;
  $self->render(text => $self->count([1], 'user'));
};

get '/count_single_with_object' => sub {
  my $self = shift;
  $self->render(text => $self->count([A::User->new]));
};

get '/count_single_with_object_and_label' => sub {
  my $self = shift;
  $self->render(text => $self->count([A::User->new], 'luser'));
};

get '/count_plural' => sub {
  my $self = shift;
  $self->render(text => $self->count([1, 2], 'user'));
};

get '/count_plural_with_object' => sub {
  my $self = shift;
  $self->render(text => $self->count([A::User->new, A::User->new]));
};

my $t = Test::Mojo->new;
$t->get_ok('/count_single')->content_is('1 user');
$t->get_ok('/count_single_with_object')->content_is('1 user');
$t->get_ok('/count_single_with_object_and_label')->content_is('1 luser');
$t->get_ok('/count_plural')->content_is('2 users');
$t->get_ok('/count_plural_with_object')->content_is('2 users');

done_testing();
