package OpenSearch::Search;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use Data::Dumper;
use OpenSearch::Search::Search;
use OpenSearch::Search::Count;
use feature qw(signatures);
no warnings qw(experimental::signatures);

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf ['OpenSearch::Base'],
  required => 1,
);

sub search( $self, @params ) {
  return ( OpenSearch::Search::Search->new( @params, _base => $self->_base )->execute );
}

sub count( $self, @params ) {
  return ( OpenSearch::Search::Count->new( @params, _base => $self->_base )->execute );
}

1;

__END__

=head1 NAME

C<OpenSearch::Search> - OpenSearch Search API Endpoints

=head1 SYNOPSIS

  use OpenSearch;

  my $os = OpenSearch->new(...);
  my $s = $os->search;

  $s->search( 
    index => 'my_index' 
    query => {...}    
  );

  $s->count( 
    index => 'my_index' 
    query => {...}    
  );

=head1 DESCRIPTION

This module provides an interface to the OpenSearch Search API endpoints.

=head1 METHODS

=over 4

=item * search

  $api->search( 
    index => 'my_index', 
    query => {...} 
  );

=item * count

  $api->count( 
    index => 'my_index', 
    query => {...} 
  );

=back

=head1 AUTHOR

C<OpenSearch::Search> Perl Module was written by Sebastian Grenz, C<< <git at fail.ninja> >>
