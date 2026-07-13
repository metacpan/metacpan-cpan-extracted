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

package OpenSearch::Client::CxnPool::Static::NoPing;
$OpenSearch::Client::CxnPool::Static::NoPing::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Role::CxnPool::Static::NoPing',
    'OpenSearch::Client::Role::Is_Sync';
use OpenSearch::Client::Util qw(throw);
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::CxnPool::Static::NoPing - A CxnPool for connecting to a remote cluster without the ability to ping.

=head1 VERSION

version 3.007008

=head1 SYNOPSIS

    $e = OpenSearch::Client->new(
        cxn_pool => 'Static::NoPing'
        nodes    => [
            'search1:9200',
            'search2:9200'
        ],
    );

=head1 DESCRIPTION

The L<Static::NoPing|OpenSearch::Client::CxnPool::Static::NoPing> connection
pool (like the L<Static|OpenSearch::Client::CxnPool::Static> pool) should be used
when your access to the cluster is limited.  However, the C<Static> pool needs
to be able to ping nodes in the cluster, with a C<HEAD /> request.  If you
can't ping your nodes, then you should use the C<Static::NoPing>
connection pool instead.

Because the cluster cannot be pinged, this CxnPool cannot use a short
ping request to determine whether nodes are live or not - it just has to
send requests to the nodes to determine whether they are alive or not.

Most of the time, a dead node will cause the request to fail quickly.
However, in situations where node failure takes time (eg malfunctioning
routers or firewalls), a failure may not be reported until the request
itself times out (see L<OpenSearch::Client::Cxn/request_timeout>).

Failed nodes will be retried regularly to check if they have recovered.

This class does L<OpenSearch::Client::Role::CxnPool::Static::NoPing> and
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

L<OpenSearch::Client::Role::Cxn/dead_timeout>

=item *

L<OpenSearch::Client::Role::Cxn/max_dead_timeout>

=back

=head2 Inherited configuration

From L<OpenSearch::Client::Role::CxnPool::Static::NoPing>

=over

=item * L<max_retries|OpenSearch::Client::Role::CxnPool::Static::NoPing/"max_retries">

=back

From L<OpenSearch::Client::Role::CxnPool>

=over

=item * L<randomize_cxns|OpenSearch::Client::Role::CxnPool/"randomize_cxns">

=back

=head1 METHODS

=head2 C<next_cxn()>

    $cxn = $cxn_pool->next_cxn

Returns the next available node  in round robin fashion - either a live node
which has previously responded successfully, or a previously failed
node which should be retried. If all nodes are dead, it will throw
a C<NoNodes> error.

=head2 Inherited methods

From L<OpenSearch::Client::Role::CxnPool::Static::NoPing>

=over

=item * L<should_mark_dead()|OpenSearch::Client::Role::CxnPool::Static::NoPing/"should_mark_dead()">

=item * L<schedule_check()|OpenSearch::Client::Role::CxnPool::Static::NoPing/"schedule_check()">

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

