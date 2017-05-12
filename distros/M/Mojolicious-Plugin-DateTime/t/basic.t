use Mojo::Base -strict;
use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

use FindBin;
use lib "$FindBin::Bin/../lib";

plugin 'DateTime';

my %dt_test = (
    year   => 2014,
    month  => 05,
    day    => 21,
    hour   => 22,
    minute => 45,
    second => 12
);

# test datetime method
get '/' => sub {
    my $self = shift;
    return $self->render( text => $self->datetime(%dt_test) );
};

# test param error
get '/param-error' => sub {
    my $self = shift;
    return $self->render( text => eval{$self->datetime} || 'error');
};

# test dt method
get '/short-way' => sub {
    my $self = shift;
    return $self->render( text => $self->dt(%dt_test) );
};

# test now method
get '/now' => sub {
    my $self = shift;
    return $self->render( text => $self->now );
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
  ->content_like(qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);

$t->get_ok('/param-error')->status_is(200)
  ->content_is('error');

$t->get_ok('/short-way')->status_is(200)
  ->content_like(qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);

$t->get_ok('/now')->status_is(200)
  ->content_like(qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);



done_testing;
