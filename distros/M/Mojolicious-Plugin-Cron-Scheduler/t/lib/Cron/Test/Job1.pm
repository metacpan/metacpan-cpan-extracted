package Cron::Test::Job1;
use v5.26;
use warnings;

use Mojo::Base qw(Mojolicious::Plugin);

use experimental qw(signatures);

sub register($self, $app, $args) {
  $app->crontask(job1 => sub {warn("Job1 was run\n")});
}

1;
