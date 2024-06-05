package OpenSearch::Filter::Source;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;
use Data::Dumper;

has 'includes' => ( is => 'rw', isa => 'ArrayRef', default => sub { []; } );
has 'excludes' => ( is => 'rw', isa => 'ArrayRef', default => sub { []; } );
has 'source'   => ( is => 'rw', isa => 'Bool',     default => sub { 1; } );

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig( source   => $_[0] ) if ( $_[0] =~ /^\d$/ );
    return $class->$orig( includes => [ $_[0] ] );
  } else {
    return $class->$orig(@_);
  }
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

sub to_hash($self) {

  #return(undef) if(!defined($self->source));
  return ('false') if ( !$self->source );                                                       #0
  return ('true')  if ( !scalar( @{ $self->includes } ) && !scalar( @{ $self->excludes } ) );
  return ( { includes => $self->includes } ) if ( !scalar( @{ $self->excludes } ) );
  return ( { excludes => $self->excludes } ) if ( !scalar( @{ $self->includes } ) );
  return ( { includes => $self->includes, excludes => $self->excludes } );
}

1;
