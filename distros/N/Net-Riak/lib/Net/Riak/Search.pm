package Net::Riak::Search;
{
  $Net::Riak::Search::VERSION = '0.1702';
}
use Moose;

#ABSTRACT: Search interface

with 'Net::Riak::Role::Base' => {classes =>
      [{name => 'client', required => 0},]};

sub search {
    my ($self, $params) = @_;
    $self->client->search($params);
};

sub setup_indexing {
    my ($self, $bucket) = @_;
    $self->client->setup_indexing($bucket);
};

1;

__END__

=pod

=head1 NAME

Net::Riak::Search - Search interface

=head1 VERSION

version 0.1702

=head1 SYNOPSIS

    my $client = Net::Riak->new(...);
    my $bucket = $client->bucket('foo');

    # retrieve an existing object
    my $obj1 = $bucket->get('foo');

    # create/store a new object
    my $obj2 = $bucket->new_object('foo2', {...});
    $object->store;

    $bucket->delete_object($key, 3); # optional w val

    # Secondary index setup
    my $obj3 = $bucket->new_object('foo3', {...});
    $obj3->add_index('index', 'first');
    $obj3->store;

    my @keys = $client->index('bucket', 'myindex_bin', 'first_value' [, 'last_value'] );

=head1 DESCRIPTION

L<Net::Riak::Search> allows you to enable indexing documents for a given bucket and querying/searching the index.

=head2 METHODS

=head3 setup_indexing

    $client->setup_indexing('bucket_name');

Does the same as :

    curl -X PUT -H "content-type:application/json" http://localhost:8098/riak/bucket_name -d '{"props":{"precommit":[{"mod":"riak_search_kv_hook","fun":"precommit"}]}'

but takes in account previouses precommits.

=head3 search

    my $response = $client->search(
        index => 'bucket_name',
        q => 'field:value'
    );
    # is the same as :
    my $response = $client->search(
        q => 'bucket_name.field:value'
    );

Search the index

=over 4

=item wt => 'XML|JSON'

defines the response format (XML is the default value as for Solr/Lucene)

=item q

the query string

=item index

is the default index you want to query, if no index is provided you have to add it as a prefix of the fields in the query string

=item rows

is the number of documents you want to be returned in the response

=item add_index

add secondary index to object

= item remove_index

remove secondary index from object

=item index

Find keys via secondary index.

=back

More parameters are available, just check at L<http://wiki.basho.com/Riak-Search---Querying.html#Querying-via-the-Solr-Interface>

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
