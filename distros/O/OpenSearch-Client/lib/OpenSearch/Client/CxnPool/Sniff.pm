# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package OpenSearch::Client::CxnPool::Sniff;
$OpenSearch::Client::CxnPool::Sniff::VERSION = '3.007009';
use Moo;
with 'OpenSearch::Client::Role::CxnPool::Sniff',
    'OpenSearch::Client::Role::Is_Sync';

use OpenSearch::Client::Util qw(throw);
use namespace::clean;

#===================================
sub next_cxn {
#===================================
    my ($self) = @_;

    $self->sniff if $self->next_sniff <= time();

    my $cxns  = $self->cxns;
    my $total = @$cxns;

    while ( 0 < $total-- ) {
        my $cxn = $cxns->[ $self->next_cxn_num ];
        return $cxn if $cxn->is_live;
    }

    throw( "NoNodes",
        "No nodes are available: [" . $self->cxns_seeds_str . ']' );
}

#===================================
sub sniff {
#===================================
    my $self = shift;

    my $cxns  = $self->cxns;
    my $total = @$cxns;
    my @skipped;

    while ( 0 < $total-- ) {
        my $cxn = $cxns->[ $self->next_cxn_num ];
        if ( $cxn->is_dead ) {
            push @skipped, $cxn;
        }
        else {
            $self->sniff_cxn($cxn) and return;
            $cxn->mark_dead;
        }
    }

    for my $cxn (@skipped) {
        $self->sniff_cxn($cxn) and return;
    }

    $self->logger->info("No live nodes available. Trying seed nodes.");
    for my $seed ( @{ $self->seed_nodes } ) {
        my $cxn = $self->cxn_factory->new_cxn($seed);
        $self->sniff_cxn($cxn) and return;
    }

}

#===================================
sub sniff_cxn {
#===================================
    my ( $self, $cxn ) = @_;
    return $self->parse_sniff( $cxn->sniff );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::CxnPool::Sniff - A CxnPool for connecting to a local cluster with a dynamic node list

=head1 VERSION

version 3.007009

=head1 SYNOPSIS

    $e = OpenSearch::Client->new(
        cxn_pool => 'Sniff',
        nodes    => [
            'search1:9200',
            'search2:9200'
        ],
    );

=head1 DESCRIPTION

The L<Sniff|OpenSearch::Client::CxnPool::Sniff> connection pool should be used
when you B<do> have direct access to the OpenSearch cluster, eg when
your client servers and OpenSearch servers are on the same network.
The nodes that you specify are used to I<discover> the cluster, which is
then I<sniffed> to find the current list of live nodes that the cluster
knows about.

This sniff process is repeated regularly, or whenever a node fails,
to update the list of healthy nodes.  So if you add more nodes to your
cluster, they will be auto-discovered during a sniff.

If all sniffed nodes fail, then it falls back to sniffing the original
I<seed> nodes that you specified in C<new()>.

For L<HTTP Cxn classes|OpenSearch::Client::Role::Cxn>, this module
will also dynamically detect the C<max_content_length> which the nodes
in the cluster will accept.

This class does L<OpenSearch::Client::Role::CxnPool::Sniff> and
L<OpenSearch::Client::Role::Is_Sync>.

=head1 CONFIGURATION

=head2 C<nodes>

The list of nodes to use to discover the cluster.  Can accept a single node,
multiple nodes, and defaults to C<localhost:9200> if no C<nodes> are
specified. See L<OpenSearch::Client::Role::Cxn/node> for details of the node
specification.

=head2 See also

=over

=item *

L<OpenSearch::Client::Role::Cxn/request_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/sniff_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/sniff_request_timeout>

=back

=head2 Inherited configuration

From L<OpenSearch::Client::Role::CxnPool::Sniff>

=over

=item * L<sniff_interval|OpenSearch::Client::Role::CxnPool::Sniff/"sniff_interval">

=item * L<sniff_max_content_length|OpenSearch::Client::Role::CxnPool::Sniff/"sniff_max_content_length">

=back

From L<OpenSearch::Client::Role::CxnPool>

=over

=item * L<randomize_cxns|OpenSearch::Client::Role::CxnPool/"randomize_cxns">

=back

=head1 METHODS

=head2 C<next_cxn()>

    $cxn = $cxn_pool->next_cxn

Returns the next available live node (in round robin fashion), or
throws a C<NoNodes> error if no nodes can be sniffed from the cluster.

=head2 C<schedule_check()>

    $cxn_pool->schedule_check

Forces a sniff before the next Cxn is returned, to updated the list of healthy
nodes in the cluster.

=head2 C<sniff()>

    $bool = $cxn_pool->sniff

Sniffs the cluster and returns C<true> if the sniff was successful.

=head2 Inherited methods

From L<OpenSearch::Client::Role::CxnPool::Sniff>

=over

=item * L<schedule_check()|OpenSearch::Client::Role::CxnPool::Sniff/"schedule_check()">

=item * L<parse_sniff()|OpenSearch::Client::Role::CxnPool::Sniff/"parse_sniff()">

=item * L<should_accept_node()|OpenSearch::Client::Role::CxnPool::Sniff/"should_accept_node()">

=back

From L<OpenSearch::Client::Role::CxnPool>

=over

=item * L<cxn_factory()|OpenSearch::Client::Role::CxnPool/"cxn_factory()">

=item * L<logger()|OpenSearch::Client::Role::CxnPool/"logger()">

=item * L<serializer()|OpenSearch::Client::Role::CxnPool/"serializer()">

=item * L<current_cxn_num()|OpenSearch::Client::Role::CxnPool/"current_cxn_num()">

=item * L<cxns()|OpenSearch::Client::Role::CxnPool/"cxns()">

=item * L<seed_nodes()|OpenSearch::Client::Role::CxnPool/"seed_nodes()">

=item * L<next_cxn_num()|OpenSearch::Client::Role::CxnPool/"next_cxn_num()">

=item * L<set_cxns()|OpenSearch::Client::Role::CxnPool/"set_cxns()">

=item * L<request_ok()|OpenSearch::Client::Role::CxnPool/"request_ok()">

=item * L<request_failed()|OpenSearch::Client::Role::CxnPool/"request_failed()">

=item * L<should_retry()|OpenSearch::Client::Role::CxnPool/"should_retry()">

=item * L<should_mark_dead()|OpenSearch::Client::Role::CxnPool/"should_mark_dead()">

=item * L<cxns_str()|OpenSearch::Client::Role::CxnPool/"cxns_str()">

=item * L<cxns_seeds_str()|OpenSearch::Client::Role::CxnPool/"cxns_seeds_str()">

=item * L<retries()|OpenSearch::Client::Role::CxnPool/"retries()">

=item * L<reset_retries()|OpenSearch::Client::Role::CxnPool/"reset_retries()">

=back

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
