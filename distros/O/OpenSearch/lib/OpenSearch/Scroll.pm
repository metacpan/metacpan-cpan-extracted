package OpenSearch::Scroll;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Mojo::UserAgent;
use Data::Dumper;

# Base singleton
has 'base'      => (is => 'rw', isa => 'OpenSearch::Base',          required => 0, lazy => 1, default => sub {OpenSearch::Base->instance;}     );

sub delete_p($self, $scroll_id) {
  #print Dumper $self->_build_request_body;
  return(
    $self->base->ua->delete_p(
      $self->base->url(
        ['_search', 'scroll', $scroll_id]
      )
    )->then( 
      sub($tx) { 
        return($self->base->response($tx));
      } 
    )->catch( 
      sub($error) { die($error . "\n") } 
    )
  );
}

sub delete($self, $scroll_id) {
  my ($res);
  $self->delete_p($scroll_id)->then(sub {$res = shift})->wait;
  return $res;
}

sub delete_all_p($self, $scroll_id) {
  $self->delete_p('_all');
}

sub delete_all($self, $scroll_id) {
  my ($res);
  $self->delete_all_p('_all')->then(sub {$res = shift})->wait;
  return($res);
}
1;