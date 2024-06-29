package OpenSearch::Filter::Nodes;
use strict;
use warnings;
use Types::Standard qw(Str Enum);
use Moo;
use feature qw(signatures);
no warnings qw(experimental::signatures);

=head1 TODO
subtype 'node_id',   as 'Str', where { $_ =~ /^[a-zA-Z0-9_]+$/ };
subtype 'node_name', as 'Str', where { $_ =~ /^[a-zA-Z0-9_\-\.]+$/ };    # Dont actually know how it may look like?
subtype 'node_ip', as 'Str',
  where { $_ =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/ };
subtype 'node_constants', as 'Str', where { $_ =~ /_local|_cluster_manager|_all|/ };
enum 'node_role' => [qw/cluster_manager data ingest voting_only ml coordinating_only/];

has 'node'       => ( is => 'rw', isa => 'node_id|node_name|node_ip|node_constants' );
has 'includes'   => ( is => 'rw', isa => 'ArrayRef[node_role]' );
has 'excludes'   => ( is => 'rw', isa => 'ArrayRef[node_role]' );
has 'attributes' => ( is => 'rw', isa => 'HashRef' );

around 'node' => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }

  return ( $self->$orig );
};

around [ 'includes', 'excludes' ] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    push( @{ $self->$orig }, @_ );
    return ($self);
  }

  return ( $self->$orig );
};

sub to_string($self) {
  return (undef) if ( !$self->node && !$self->includes && !$self->excludes );
  print "NODE: " . $self->node . "\n";

  if ( $self->node ) {
    if ( $self->includes || $self->excludes ) {
      die( 'Node is set to: ' . $self->node . '. In/Excludes and attributes will be ommited.' );
    }
    return ( $self->node );
  }

  if ( $self->attributes ) {
    return ( join( ',', map { $_ . ':' . $self->attributes->{$_} } keys( %{ $self->attributes } ) ) );
  }

  if ( $self->excludes && !$self->includes ) {
    return ( join( ',', '_all', ( map { $_ . ':false' } @{ $self->excludes } ) ) );
  } elsif ( $self->includes && !$self->includes ) {
    return ( join( ',', ( map { $_ . ':true' } @{ $self->excludes } ) ) );
  } elsif ( $self->includes && $self->excludes ) {

    # Does this even work or make sense?
    return (
      join( ',', ( map { $_ . ':true' } @{ $self->includes } ), ( map { $_ . ':false' } @{ $self->excludes } ) ) );
  }

}
=cut
1;
