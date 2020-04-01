#!/usr/bin/env perl
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'Notifications' => {
  JSON => 1,
  'HTML' => 1
};

get '/' => sub {
  my $c = shift;
  $c->notify(error => q/Invalid/);
  return $c->render(inline => <<HTML);
  <p><%= notifications 'html' %></p>
HTML
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->content_like(qr!<p><div class="notify notify-error">Invalid</div>!)
  ;

done_testing;
