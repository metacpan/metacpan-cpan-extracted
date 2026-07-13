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

package OpenSearch::Client::Role::CxnPool::Sniff;
$OpenSearch::Client::Role::CxnPool::Sniff::VERSION = '3.007008';
use Moo::Role;
with 'OpenSearch::Client::Role::CxnPool';
requires 'next_cxn', 'sniff';
use namespace::clean;

use OpenSearch::Client::Util qw(parse_params);
use List::Util qw(min);
use Try::Tiny;

has 'sniff_interval' => ( is => 'ro', default => 300 );
has 'next_sniff'     => ( is => 'rw', default => 0 );
has 'sniff_max_content_length' => ( is => 'ro' );

#===================================
sub BUILDARGS {
#===================================
    my ( $class, $params ) = parse_params(@_);
    $params->{sniff_max_content_length} = !$params->{max_content_length}
        unless defined $params->{sniff_max_content_length};
    return $params;
}

#===================================
sub schedule_check {
#===================================
    my $self = shift;
    $self->logger->info("Require sniff before next request");
    $self->next_sniff(-1);
}

#===================================
sub parse_sniff {
#===================================
    my $self = shift;
    my $nodes = shift or return;
    my @live_nodes;
    my $max       = 0;
    my $sniff_max = $self->sniff_max_content_length;

    for my $node_id ( keys %$nodes ) {
        my $data = $nodes->{$node_id};

        my $addr = $data->{http}{publish_address} || $data->{http_address};
        my $host = $self->_extract_host($addr)
            or next;

        $host = $self->should_accept_node( $host, $node_id, $data )
            or next;

        push @live_nodes, $host;
        next unless $sniff_max and $data->{http};

        my $node_max = $data->{http}{max_content_length_in_bytes} || 0;
        $max
            = $node_max == 0 ? $max
            : $max == 0      ? $node_max
            :                  min( $node_max, $max );
    }

    return unless @live_nodes;

    $self->cxn_factory->max_content_length($max)
        if $sniff_max and $max;

    $self->set_cxns(@live_nodes);
    my $next = $self->next_sniff( time() + $self->sniff_interval );
    $self->logger->infof( "Next sniff at: %s", scalar localtime($next) );

    return 1;
}

#===================================
sub _extract_host {
#===================================
    my $self = shift;
    my $host = shift || return;
    $host =~ s{^inet\[(.+)\]$}{$1};
    $host =~ s{^[^/]*/}{};
    return $host;
}

#===================================
sub should_accept_node { return $_[1] }
#===================================

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::CxnPool::Sniff - A CxnPool role for connecting to a local cluster with a dynamic node list

=head1 VERSION

version 3.007008

=head1 CONFIGURATION

=head2 C<sniff_interval>

How often should we perform a sniff in order to detect whether new nodes
have been added to the cluster.  Defaults to `300` seconds.

=head2 C<sniff_max_content_length>

Whether we should set the
L<max_content_length|OpenSearch::Client::Role::Cxn/max_content_length>
dynamically while sniffing. Defaults to true unless a fixed
C<max_content_length> was specified.

=head1 METHODS

=head2 C<schedule_check()>

    $cxn_pool->schedule_check

Schedules a sniff before the next request is processed.

=head2 C<parse_sniff()>

    $bool = $cxn_pool->parse_sniff(\%nodes);

Parses the response from a sniff request and extracts the hostname/ip
of all listed nodes, filtered through L</should_accept_node()>. If any live
nodes are found, they are passed to L<OpenSearch::Client::Role::CxnPool/set_cxns()>.
The L<max_content_length|OpenSearch::Client::Role::Cxn/max_content_length>
is also detected if L</sniff_max_content_length> is true.

=head2 C<should_accept_node()>

    $host = $cxn_pool->should_accept_node($host,$node_id,\%node_data)

This method serves as a hook which can be overridden by the user.  When
a sniff is performed, this method is called with the C<host>
(eg C<192.168.5.100:9200>), the C<node_id> (the ID assigned to the node
by OpenSearch) and the C<node_data> which contains the information
about the node that OpenSearch has returned, eg:

    {
        'transport_address' => '192.168.5.100:9300',
        'http' => {
            'publish_address'   => '192.168.5.100:9200',
            'bound_address'     => [ '[::]:9200' ],
            'max_content_length_in_bytes' => 104857600
        }
        'name'          => 'super-node-100',
        'host'          => '192.168.5.100',
        'ip'            => '192.168.5.100',
        'version'       => '3.7.0',
        'roles'         => [
            'cluster_manager',
            'data',
            'ingest',
            'remote_cluster_client'
        ],
        'attributes'    => {
            'shard_indexing_pressure_enabled' => 'true'
         },
    }

    
If the node should be I<accepted> (ie used to serve data), then it should
return the C<host> value to use.  By default, nodes are always
accepted.

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
