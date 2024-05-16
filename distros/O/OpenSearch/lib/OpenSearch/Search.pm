package OpenSearch::Search;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use OpenSearch::Scroll;
use Data::Dumper;

with 'OpenSearch::Parameters::Search';

#with 'OpenSearch::Helper';

# Base singleton
has 'base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

# Scroll parameters
has 'scroll_id' => ( is => 'rw', isa => 'Str' );

sub execute_p($self) {
  my $params = {
    optional => {
      url => [
        qw/
          max_concurrent_shard_requests stored_fields ignore_throttled allow_no_indices q request_cache analyze_wildcard suggest_text
          rest_total_hits_as_int routing track_total_hits cancel_after_time_interval _source_includes pre_filter_shard_size suggest_field
          preference suggest_size default_operator suggest_mode allow_partial_search_results search_type expand_wildcards typed_keys
          ignore_unavailable df batched_reduce_size analyzer _source_excludes track_scores lenient ccs_minimize_roundtrips scroll
          /
      ],
      body => [
        qw/
          seq_no_primary_term version explain stats from min_score size terminate_after docvalue_fields indices_boost fields query _source timeout size sort search_after
          /
      ]
    }
  };

  return ( $self->base->_get( $self, [ ( $self->index // () ), '_search' ], $params ) );
}

sub execute($self) {
  my ($res);
  $self->execute_p->then( sub { $res = shift; } )->wait;
  return $res;
}

sub search_scroll_p($self) {
  if ( $self->scroll_id ) {
    $self->base->ua->get_p(
      $self->base->url( [ '_search', 'scroll' ] ) => json => {
        scroll    => $self->scroll // '10m',
        scroll_id => $self->scroll_id,

        # slice => {id => 0, max => 10} These belong only in the initial searech request. not here
      }
    )->then( sub($tx) {
      $self->scroll_id( $tx->result->json->{_scroll_id} ) if $tx->result->json->{_scroll_id};
      return ( $self->base->response($tx) );
    } )->catch( sub($error) {
      die( $error . "\n" );
    } );
  } else {

    # If not already in "scroll" mode, use a normal search including scroll
    $self->search_p;
  }
}

sub search_scroll($self) {
  my ($res);
  $self->search_scroll_p->then( sub { $res = shift; } )->wait;
  return $res;
}

sub scroll_delete_p($self) {
  return ( OpenSearch::Scroll->new->delete_p( $self->scroll_id ) );
}

sub scroll_delete($self) {
  my ($res);
  my $scroll = OpenSearch::Scroll->new;
  $scroll->delete_p( $self->scroll_id )->then( sub { $res = shift } )->wait;
  return ($res);
}

1;
