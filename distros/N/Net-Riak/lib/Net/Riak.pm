package Net::Riak;
{
  $Net::Riak::VERSION = '0.1702';
}

# ABSTRACT: Interface to Riak

use Moose;

use Net::Riak::Client;
use Net::Riak::Bucket;
use Net::Riak::Types Client => { -as => 'Client_T' };

with 'Net::Riak::Role::MapReduce';

has client => (
    is       => 'rw',
    isa      => Client_T,
    required => 1,
    handles  => [qw/is_alive all_buckets server_info stats search index setup_indexing/]
);

sub BUILDARGS {
    my ($class, %args) = @_;

    my $transport = $args{transport} || 'REST';
    my $trait = "Net::Riak::Transport::".$transport;

    my $client = Net::Riak::Client->with_traits($trait)->new(%args);
    $args{client} = $client;
    \%args;
}

sub bucket {
    my ($self, $name) = @_;
    my $bucket = Net::Riak::Bucket->new(name => $name, client => $self->client);
    $bucket;
}

1;

__END__

=pod

=head1 NAME

Net::Riak - Interface to Riak

=head1 VERSION

version 0.1702

=head1 SYNOPSIS

    # REST interface
    my $client = Net::Riak->new(
        host => 'http://10.0.0.40:8098',
        ua_timeout => 900,
    );

    # Or PBC interface.
    my $client = Net::Riak->new(
        transport => 'PBC',
        host => '10.0.0.40',
        port => 8080
    );

    my $bucket = $client->bucket('blog');
    my $obj    = $bucket->new_object('new_post', {title => 'foo', content => 'bar'});
    $obj->store;

    $obj = $bucket->get('new_post');
    say "title for ".$obj->key." is ".$obj->data->{title};

    # Indexing and searching (REST interface)
    $client->setup_indexing("bucket_name");
    ...adding documents to riak...
    my $response = $client->search(
        index => 'bucket_name',
        q     => 'field:value'
    );

    # Secondary index setup (REST interface)
    my $obj3 = $bucket->new_object('foo3', {...});
    $obj3->add_index('myindex_bin','myvalue' );
    $obj3->add_index('number_int', 1001);
    $obj3->store;

    # Get all keys for a specific index/value pair
    my @keys = $client->index('mybucket', 'myindex_bin', 'myvalue' );

    # Get all keys for a range of index value pairs
    my @keys = $client->index('mybucket', 'number_int', 500, 1500);

    # Removing a secondary index (REST interface)
    my $new_obj = $bucket->get('foo3');
    $new_obj->remove_index('number_int', 1001);
    $new_obj->store;

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 2

=item B<host>

REST: The URL of the node

PBC: The hostname of the node

default 'http://127.0.0.1:8098'

Note that providing multiple hosts is now deprecated.

=item B<port>

Port of the PBC interface.

=item B<transport>

Used to select the PB protocol by passing in 'PBC'

=item B<prefix>

Interface prefix (default 'riak')

=item B<mapred_prefix>

MapReduce prefix (default 'mapred')

=item B<r>

R value setting for this client (default 2)

=item B<w>

W value setting for this client (default 2)

=item B<dw>

DW value setting for this client (default 2)

=item B<client_id>

client_id for this client

=item B<ua_timeout (REST only)>

timeout for L<LWP::UserAgent> in seconds, defaults to 3.

=item B<disable_return_body (REST only)>

Disable returning of object content in response in a store operation.

If set to true and the object has siblings these will not be available without an additional fetch.

This will become the default behaviour in 0.17

=back

=head1 METHODS

=head2 bucket

    my $bucket = $client->bucket($name);

Get the bucket by the specified name. Since buckets always exist, this will always return a L<Net::Riak::Bucket>

=head2 is_alive

    if (!$client->is_alive) {
        ...
    }

Check if the Riak server for this client is alive

=head2 all_buckets

List all buckets, requires Riak 0.14+ or PBC connection.

=head2 add

    my $map_reduce = $client->add('bucket_name', 'key');

Start assembling a Map/Reduce operation

=head2 link

    my $map_reduce = $client->link();

Start assembling a Map/Reduce operation

=head2 map

    my $map_reduce = $client->add('bucket_name', 'key')->map("function ...");

Start assembling a Map/Reduce operation

=head2 reduce

    my $map_reduce = $client->add(..)->map(..)->reduce("function ...");

Start assembling a Map/Reduce operation

=head2 server_info (PBC only)

    $client->server_info->{server_version};

=head2 stats (REST only)

    say Dumper $client->stats;

=head2 search (REST only)

    $client->search( index => 'bucket_name', q => 'field:value' );

Makes a query to the index (see L<Net::Riak::Search> for more details on parameters)

=head2 setup_indexing (REST only)

    $client->setup_indexing('bucket_name');

Define precommit hook in order to enable indexing documents written into the given bucket

=head1 SEE ALSO

L<Net::Riak::MapReduce>

L<Net::Riak::Object>

L<Net::Riak::Bucket>

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
