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

package OpenSearch::Client::Role::CxnPool::Static;
$OpenSearch::Client::Role::CxnPool::Static::VERSION = '3.007009';
use Moo::Role;
with 'OpenSearch::Client::Role::CxnPool';
requires 'next_cxn';

use namespace::clean;

#===================================
sub BUILD {
#===================================
    my $self = shift;
    $self->set_cxns( @{ $self->seed_nodes } );
    $self->schedule_check;
}

#===================================
sub schedule_check {
#===================================
    my ($self) = @_;
    $self->logger->info("Forcing ping before next use on all live cxns");
    for my $cxn ( @{ $self->cxns } ) {
        next if $cxn->is_dead;
        $self->logger->infof( "Ping [%s] before next request",
            $cxn->stringify );
        $cxn->force_ping;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::CxnPool::Static - A CxnPool role for connecting to a remote cluster with a static list of nodes.

=head1 VERSION

version 3.007009

=head1 METHODS

=head2 C<schedule_check()>

    $cxn_pool->schedule_check

Forces a ping on each cxn in L<cxns()|OpenSearch::Client::Role::CxnPool/cxns()>
before the next time that cxn is used for a request.

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

