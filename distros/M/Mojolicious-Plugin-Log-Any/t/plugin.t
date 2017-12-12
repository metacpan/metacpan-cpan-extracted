use strict;
use warnings;
use Mojo::Log;
use Mojo::Util 'dumper';
use Test::Mojo;
use Test::More;

my @levels = qw(debug info warn error fatal);

my @full_log;
my $full_logger = Mojo::Log->new;
$full_logger->unsubscribe('message')->on(message => sub { push @full_log, [$_[1], $_[2]] });

{package My::Test::App;
  use Mojo::Base 'Mojolicious';
  sub startup {
    my $self = shift;
    $self->plugin('Log::Any' => {logger => $full_logger});
    foreach my $level (@levels) {
      $self->routes->get("/$level" => sub {
        my $c = shift;
        $c->app->log->$level('full');
        $c->render(text => '');
      });
    }
  }
}

my @lite_log;
my $lite_logger = Mojo::Log->new;
$lite_logger->unsubscribe('message')->on(message => sub { push @lite_log, [$_[1], $_[2]] });

use Mojolicious::Lite;
plugin 'Log::Any' => {logger => $lite_logger};
foreach my $level (@levels) {
  get "/$level" => sub {
    my $c = shift;
    $c->app->log->$level('lite');
    $c->render(text => '');
  };
}

my $t = Test::Mojo->new;
foreach my $level (@levels) {
  @lite_log = ();
  
  $t->get_ok("/$level");
  
  ok +(grep { $_->[0] eq $level and $_->[1] eq 'lite' } @lite_log), "$level log message"
    or diag dumper \@lite_log;
}

$t = Test::Mojo->new('My::Test::App');
foreach my $level (@levels) {
  @full_log = ();
  
  $t->get_ok("/$level");
  
  ok +(grep { $_->[0] eq $level and $_->[1] eq 'full' } @full_log), "$level log message"
    or diag dumper \@full_log;
}

done_testing;
