package OpenSearch::Remote::Info;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use Mojo::UserAgent;

# Base singleton
has 'base' => (is => 'rw', isa => 'OpenSearch::Base', lazy => 1, default => sub {OpenSearch::Base->instance});

sub info_p($self) {
  return($self->base->_get(
    ['_remote', 'info']
  ));
}

sub info($self) {
  my ($res);
  $self->info_p->then(sub {$res = shift; })->wait;
  return $res;
}

1;
