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

package OpenSearch::Client::Core::3_0::Role::Helper::Scroll;
$OpenSearch::Client::Core::3_0::Role::Helper::Scroll::VERSION = '3.007009';
use Moo::Role;
requires 'finish';
use OpenSearch::Client::Util qw(parse_params throw);
use Devel::GlobalDestruction;
use namespace::clean;
has 'os'            => ( is => 'ro', required => 1 );
has 'scroll'        => ( is => 'ro' );
has 'total'         => ( is => 'rwp' );
has 'max_score'     => ( is => 'rwp' );
has 'facets'        => ( is => 'rwp' );
has 'aggregations'  => ( is => 'rwp' );
has 'suggest'       => ( is => 'rwp' );
has 'took'          => ( is => 'rwp' );
has 'total_took'    => ( is => 'rwp' );
has 'search_params' => ( is => 'ro' );
has 'is_finished'   => ( is => 'rwp', default => '' );
has '_pid'          => ( is => 'ro', default => sub {$$} );
has '_scroll_id'    => ( is => 'rwp', clearer => 1, predicate => 1 );

## help use of this as a drop in for Search::Elasticsearch
sub es { shift->os; }

#===================================
sub scroll_request {
#===================================
    my $self = shift;
    throw( 'Illegal',
              'Scroll requests are not fork safe and may only be '
            . 'refilled by the same process that created the instance.' )
        if $self->_pid != $$;

    my %args = ( scroll => $self->scroll );
    $args{body} = { scroll_id => $self->_scroll_id };
    $self->es->scroll(%args);
}

#===================================
sub DEMOLISH {
#===================================
    my $self = shift or return;
    return if in_global_destruction;
    $self->finish;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Core::3_0::Role::Helper::Scroll - Provides common functionality to L<OpenSearch::Client::Core::3_0::Helper::Scroll>

=head1 VERSION

version 3.007009

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