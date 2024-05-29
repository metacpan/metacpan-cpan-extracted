package OpenSearch::Index;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Index::SetAliases;
use OpenSearch::Index::GetAliases;
use OpenSearch::Index::ClearCache;
use OpenSearch::Index::Clone;
use OpenSearch::Index::Close;
use OpenSearch::Index::Create;
use OpenSearch::Index::SetMappings;
use OpenSearch::Index::GetMappings;
use OpenSearch::Index::GetDangling;
use OpenSearch::Index::ImportDangling;
use OpenSearch::Index::DeleteDangling;
use OpenSearch::Index::Delete;
use OpenSearch::Index::ForceMerge;
use OpenSearch::Index::Get;
use OpenSearch::Index::GetSettings;
use OpenSearch::Index::Exists;
use OpenSearch::Index::Open;
use OpenSearch::Index::Refresh;
use OpenSearch::Index::Shrink;
use OpenSearch::Index::Split;
use OpenSearch::Index::Stats;
use OpenSearch::Index::UpdateSettings;

sub create( $self, @params ) {
  return ( OpenSearch::Index::Create->new(@params)->execute );
}

sub delete( $self, @params ) {
  return ( OpenSearch::Index::Delete->new(@params)->execute );
}

sub set_aliases( $self, @params ) {
  return ( OpenSearch::Index::SetAliases->new(@params)->execute );
}

sub get_aliases( $self, @params ) {
  return ( OpenSearch::Index::GetAliases->new(@params)->execute );
}

sub clear_cache( $self, @params ) {
  return ( OpenSearch::Index::ClearCache->new(@params)->execute );
}

sub clone( $self, @params ) {
  return ( OpenSearch::Index::Clone->new(@params)->execute );
}

sub close( $self, @params ) {
  return ( OpenSearch::Index::Close->new(@params)->execute );
}

sub set_mappings( $self, @params ) {
  return ( OpenSearch::Index::SetMappings->new(@params)->execute );
}

sub get_mappings( $self, @params ) {
  return ( OpenSearch::Index::GetMappings->new(@params)->execute );
}

sub get_dangling( $self, @params ) {
  return ( OpenSearch::Index::GetDangling->new(@params)->execute );
}

sub import_dangling( $self, @params ) {
  return ( OpenSearch::Index::ImportDangling->new(@params)->execute );
}

sub delete_dangling( $self, @params ) {
  return ( OpenSearch::Index::DeleteDangling->new(@params)->execute );
}

sub get( $self, @params ) {
  return ( OpenSearch::Index::Get->new(@params)->execute );
}

sub exists( $self, @params ) {
  return ( OpenSearch::Index::Exists->new(@params)->execute );
}

sub force_merge( $self, @params ) {
  return ( OpenSearch::Index::ForceMerge->new(@params)->execute );
}

sub open( $self, @params ) {
  return ( OpenSearch::Index::Open->new(@params)->execute );
}

sub refresh( $self, @params ) {
  return ( OpenSearch::Index::Refresh->new(@params)->execute );
}

sub shrink( $self, @params ) {
  return ( OpenSearch::Index::Shrink->new(@params)->execute );
}

sub split( $self, @params ) {
  return ( OpenSearch::Index::Split->new(@params)->execute );
}

sub stats( $self, @params ) {
  return ( OpenSearch::Index::Stats->new(@params)->execute );
}

sub get_settings( $self, @params ) {
  return ( OpenSearch::Index::GetSettings->new(@params)->execute );
}

sub update_settings( $self, @params ) {
  return ( OpenSearch::Index::UpdateSettings->new(@params)->execute );
}

1;

__END__

=head1 NAME

C<OpenSearch::Index> - OpenSearch Index API Endpoints

=head1 SYNOPSIS

  use OpenSearch;

  my $os = OpenSearch->new(...);
  my $api = $os->index;

  $api->create( index => 'my_index' );
  $api->delete( index => 'my_index' );
  #...

=head1 DESCRIPTION

This module provides an interface to the OpenSearch Index API endpoints.
If i read the documentation correctly, all endpoints are supported. For
a list of avaialable parameters see: 
L<https://opensearch.org/docs/latest/api-reference/index-apis/>

=head1 RETURN VALUES

When the C<async> attribute is set to true:

  my $os = OpenSearch->new(
    ...
    async => 1
  );

all methods return a L<Mojo::Promise> object that will resolve 
to a L<OpenSearch::Response> object. Otherwise, it will directly return a
L<OpenSearch::Response> object.

=head1 METHODS

=over 4

=item * create

  $api->create( index => 'my_index' );

  # With addtional parameters
  $api->create( 
    index => 'my_index',
    timeout => '1m'
  );

=item * delete

  $api->delete( index => 'my_index' );

  # With addtional parameters
  $api->delete( 
    index => 'my_index',
    ignore_unavailable => 1
  );

Deletes an index.

=item * set_aliases

  $api->set_aliases( 
    index => 'my_index', 
    actions => [ 
      { 
        add => { index => 'my_index', alias => 'my_alias' } 
      },
      { 
        remove => { index => 'my_index_old', alias => 'my_alias_old' } 
      }
    ]);

=item * get_aliases

  $api->get_aliases( index => 'my_index' );

Get aliases for an index.

=item * clear_cache

  $api->clear_cache( index => 'my_index' );

Clears the cache for an index.

=item * clone

  $api->clone( 
    index => 'my_index', 
    target => 'my_index_clone',
    settings => { 
      index => {number_of_shards => 1} 
    },
    aliases => {
      my_alias => {}
    }
  );

Clones an index.

=item * close

  $api->close( index => 'my_index' );

Closes an index.

=item * set_mappings

  $api->set_mappings( 
    index => 'my_index', 
    properties => {
      my_field => { type => 'text' }
    },
    dynamic => 'strict'
  );

Sets mappings for an index.

=item * get_mappings

  $api->get_mappings( 
    index => 'my_index' 
    field => 'my_field'
  );

Get mappings for an index.

=item * get_dangling

  $api->get_dangling;

Get dangling indices.

=item * import_dangling

  $api->import_dangling( 
    index_uuid => 'my_index_uuid' 
  );

Import a dangling index.

=item * delete_dangling

  $api->delete_dangling( 
    index_uuid => 'my_index_uuid' 
  );

Delete a dangling index.

=item * get

  $api->get( index => 'my_index' );

Get an index.

=item * exists

  $api->exists( index => 'my_index' );

Check if an index exists.

=item * force_merge

  $api->force_merge( index => 'my_index' );

Force merge an index.

=item * open

  $api->open( index => 'my_index' );

Open an index.

=item * refresh

  $api->refresh( index => 'my_index' );

Refresh an index.

=item * shrink

  $api->shrink( 
    index => 'my_index', 
    target => 'my_index_shrink',
    settings => { 
      index => {number_of_shards => 1} 
    }
  );

Shrink an index.

=item * split

  $api->split( 
    index => 'my_index', 
    target => 'my_index_split',
    settings => { 
      index => {number_of_shards => 1} 
    },
    aliases => {
      my_alias => {}
    }
  );

Split an index.

=item * stats

  $api->stats( index => 'my_index' );
  $api->stats( index => 'my_index', metrics => 'docs' );

Get stats for an index.

=item * get_settings

  $api->get_settings( 
    index => 'my_index' 
    flat_settings => 1
  );

Get settings for an index.

=item * update_settings

  $api->update_settings( 
    index => 'my_index', 
    settings => { 
      index => {number_of_shards => 1},
      "index.number_of_replicas" => 5
    }
  );

Update settings for an index.

=back

=head1 AUTHOR

C<OpenSearch::Index> Perl Module was written by Sebastian Grenz, C<< <git at fail.ninja> >>
