package OpenSearch::Document;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use Data::Dumper;
use OpenSearch::Document::Index;
use OpenSearch::Document::Bulk;
use OpenSearch::Document::Get;
use feature qw(signatures);
no warnings qw(experimental::signatures);

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf ['OpenSearch::Base'],
  required => 1,
);

sub index( $self, @params ) {
  return ( OpenSearch::Document::Index->new( @params, _base => $self->_base )->execute );
}

sub bulk( $self, @params ) {
  return ( OpenSearch::Document::Bulk->new( @params, _base => $self->_base )->execute );
}

sub get( $self, @params ) {
  return ( OpenSearch::Document::Get->new( @params, _base => $self->_base )->execute );
}

1;

__END__

=head1 NAME

C<OpenSearch::Document> - OpenSearch Document API Endpoints

=head1 SYNOPSIS

  use OpenSearch;

  my $os = OpenSearch->new(...);
  my $document = $os->document;



=head1 DESCRIPTION

This module provides an interface to the OpenSearch Document API endpoints.

=head1 METHODS

=head2 index

Index a single document.

  my $res = $document->index(
    index => 'my_index',
    doc   => {
      user_agent => {
        name   => "Chrome",
        device => {
          name => "Other"
        }
      }
    } 
  );

=head2 bulk

Index multiple documents. See the OpenSearch Bulk API documentation for more information.

  my $res = $document->bulk(
    index => 'my_index',
    docs  => [
      {create => {}},
      {
        user_agent => {
          name   => "Chrome",
          device => {
            name => "Other"
          }
        }
      },
    ]
  );


  my $res = $document->bulk(
    { create => { _index => "movies", _id => "tt1392214" } }
    { title => Prisoners, year => 2013 }

  );

=head2 get

Retrieve a single document.

  my $res = $document->get(
    index => 'my_index',
    id    => 1337
  );

=head1 AUTHOR

C<OpenSearch> was written by Sebastian Grenz, C<< <git at fail.ninja> >>
