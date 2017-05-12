#!/usr/bin/env perl

package Custom;

use base 'MojoX::Validator';

sub new {
    my $self = shift->SUPER::new(@_);

    $self->field('foo')->required(1)->length(3, 10);

    return $self;
}

package Decamelized;
use base 'Custom';

package WrongIsa;

sub new { }

package Broken;

use base 'MojoX::Validator';

sub new {
    die 'broken!';
}

package UnknownParams;
use base 'MojoX::Validator';

sub new { shift->SUPER::new(@_, explicit => 1) }

package main;

use strict;
use warnings;

use Test::More;

plan tests => 34;

use Mojolicious::Lite;

plugin 'validator';

post '/' => sub {
    my $self = shift;

    my $validator = $self->create_validator;

    $validator->field('foo')->required(1)->length(3, 10);

    if ($self->validate($validator)) {
        return $self->render('ok');
    }
} => 'form';

post '/custom' => sub {
    my $self = shift;

    my $validator = $self->create_validator('Custom');

    if ($self->validate($validator)) {
        return $self->render('ok');
    }

    $self->render('form');
} => 'custom';

post '/decamelized' => sub {
    my $self = shift;

    my $validator = $self->create_validator('decamelized');

    if ($self->validate($validator)) {
        return $self->render('ok');
    }

    $self->render('form');
} => 'decamelized';

post '/broken' => sub {
    my $self = shift;

    $self->create_validator('Broken');
} => 'broken';

post '/wrong-isa' => sub {
    my $self = shift;

    $self->create_validator('WrongIsa');
} => 'wrong-isa';

post '/has-unknown-params' => sub {
    my $self = shift;

    my $validator = $self->create_validator('UnknownParams');

    $self->render(template => 'unknown', status => 501) if !$self->validate($validator);

} => 'has-unknown-params';

use Test::Mojo;

my $t = Test::Mojo->new;

#$ENV{MOJO_LOG_LEVEL} = 'debug';

for my $path ('', 'custom', 'decamelized') {
    $t->post_ok("/$path" => form => {})->status_is(200)
      ->content_like(qr/required/i);
    $t->post_ok("/$path" => form => {foo => '12345678901'})->status_is(200)
      ->content_like(qr/length/i);
    $t->post_ok("/$path" => form => {foo => '123'})->status_is(200)
      ->content_like(qr/ok/i);
}

$t->post_ok('/wrong-isa' => form => {})->status_is(500);
$t->post_ok('/broken'    => form => {})->status_is(500);

$t->post_ok('/has-unknown-params' => form => { not => 'specified' })
  ->status_is(501)
  ->content_is("1\n");

__DATA__

@@ form.html.ep
%= form_for 'form', method => 'post' => begin
    <%= input_tag 'foo' %>
    <%= validator_error 'foo' %>
%= end

@@ ok.html.ep
OK

@@ unknown.html.ep
<%= validator_has_unknown_params %>
