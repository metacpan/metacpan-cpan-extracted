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

package OpenSearch::Client::CxnPool::Static;
$OpenSearch::Client::CxnPool::Static::VERSION = '3.007002';
use Moo;
with 'OpenSearch::Client::Role::CxnPool::Static',
    'OpenSearch::Client::Role::Is_Sync';
use OpenSearch::Client::Util qw(throw);
use namespace::clean;

#===================================
sub next_cxn {
#===================================
    my ($self) = @_;

    my $cxns  = $self->cxns;
    my $total = @$cxns;

    my $now = time();
    my @skipped;

    while ( $total-- ) {
        my $cxn = $cxns->[ $self->next_cxn_num ];
        return $cxn if $cxn->is_live;

        if ( $cxn->next_ping < $now ) {
            return $cxn if $cxn->pings_ok;
        }
        else {
            push @skipped, $cxn;
        }
    }

    for my $cxn (@skipped) {
        return $cxn if $cxn->pings_ok;
    }

    $_->force_ping for @$cxns;

    throw( "NoNodes", "No nodes are available: [" . $self->cxns_str . ']' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::CxnPool::Static - A CxnPool for connecting to a remote cluster with a static list of nodes.

=head1 VERSION

version 3.007002

=head1 SYNOPSIS

    $e = OpenSearch::Client->new(
        cxn_pool => 'Static'     # default
        nodes    => [
            'search1:9200',
            'search2:9200'
        ],
    );

=head1 DESCRIPTION

The L<Static|OpenSearch::Client::CxnPool::Static> connection pool, which is the
default, should be used when you don't have direct access to the OpenSearch
cluster, eg when you are accessing the cluster through a proxy.  It
round-robins through the nodes that you specified, and pings each node
before it is used for  the first time, to ensure that it is responding.

If any node fails, then all nodes are pinged before the next request to
ensure that they are still alive and responding.  Failed nodes will be
pinged regularly to check if they have recovered.

This class does L<OpenSearch::Client::Role::CxnPool::Static> and
L<OpenSearch::Client::Role::Is_Sync>.

=head1 CONFIGURATION

=head2 C<nodes>

The list of nodes to use to serve requests.  Can accept a single node,
multiple nodes, and defaults to C<localhost:9200> if no C<nodes> are
specified. See L<OpenSearch::Client::Role::Cxn/node> for details of the node
specification.

=head2 See also

=over

=item *

L<OpenSearch::Client::Role::Cxn/request_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/ping_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/dead_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/max_dead_timeout>

=back

=head2 Inherited configuration

From L<OpenSearch::Client::Role::CxnPool>

=over

=item * L<randomize_cxns|OpenSearch::Client::Role::CxnPool/"randomize_cxns">

=back

=head1 METHODS

=head2 C<next_cxn()>

    $cxn = $cxn_pool->next_cxn

Returns the next available live node (in round robin fashion), or
throws a C<NoNodes> error if no nodes respond to ping requests.

=head2 Inherited methods

From L<OpenSearch::Client::Role::CxnPool::Static>

=over

=item * L<schedule_check()|OpenSearch::Client::Role::CxnPool::Static/"schedule_check()">

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
