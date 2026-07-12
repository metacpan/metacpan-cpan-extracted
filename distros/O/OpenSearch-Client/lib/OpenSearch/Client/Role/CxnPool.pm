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

package OpenSearch::Client::Role::CxnPool;
$OpenSearch::Client::Role::CxnPool::VERSION = '3.007007';
use Moo::Role;
use OpenSearch::Client::Util qw(parse_params);
use List::Util qw(shuffle);
use IO::Select();
use Time::HiRes qw(time sleep);
use OpenSearch::Client::Util qw(to_list);
use namespace::clean;

requires qw(next_cxn schedule_check);

has 'cxn_factory'     => ( is => 'ro',  required => 1 );
has 'logger'          => ( is => 'ro',  required => 1 );
has 'serializer'      => ( is => 'ro',  required => 1 );
has 'current_cxn_num' => ( is => 'rwp', default  => 0 );
has 'cxns'            => ( is => 'rwp', default  => sub { [] } );
has 'seed_nodes'      => ( is => 'ro',  required => 1 );
has 'retries'         => ( is => 'rw',  default  => 0 );
has 'randomize_cxns'  => ( is => 'ro',  default  => 1 );

#===================================
around BUILDARGS => sub {
#===================================
    my $orig   = shift;
    my $params = $orig->(@_);
    my @seed   = grep {$_} to_list( delete $params->{nodes} || ('') );

    @seed = $params->{cxn_factory}->default_host
        unless @seed;
    $params->{seed_nodes} = \@seed;
    return $params;
};

#===================================
sub next_cxn_num {
#===================================
    my $self = shift;
    my $cxns = $self->cxns;
    return unless @$cxns;
    my $current = $self->current_cxn_num;
    $self->_set_current_cxn_num( ( $current + 1 ) % @$cxns );
    return $current;
}

#===================================
sub set_cxns {
#===================================
    my $self    = shift;
    my $factory = $self->cxn_factory;
    my @cxns    = map { $factory->new_cxn($_) } @_;
    @cxns = shuffle @cxns if $self->randomize_cxns;
    $self->_set_cxns( \@cxns );
    $self->_set_current_cxn_num(0);

    $self->logger->infof( "Current cxns: %s",
        [ map { $_->stringify } @cxns ] );

    return;
}

#===================================
sub request_ok {
#===================================
    my ( $self, $cxn ) = @_;
    $cxn->mark_live;
    $self->reset_retries;
}

#===================================
sub request_failed {
#===================================
    my ( $self, $cxn, $error ) = @_;

    if ( $error->is( 'Cxn', 'Timeout' ) ) {
        $cxn->mark_dead if $self->should_mark_dead($error);
        $self->schedule_check;

        if ( $self->should_retry($error) ) {
            my $retries = $self->retries( $self->retries + 1 );
            return 1 if $retries < $self->_max_retries;
        }
    }
    else {
        $cxn->mark_live if $cxn;
    }
    $self->reset_retries;
    return 0;
}

#===================================
sub should_retry {
#===================================
    my ( $self, $error ) = @_;
    return $error->is('Cxn');
}

#===================================
sub should_mark_dead {
#===================================
    my ( $self, $error ) = @_;
    return $error->is('Cxn');
}

#===================================
sub cxns_str {
#===================================
    my $self = shift;
    join ", ", map { $_->stringify } @{ $self->cxns };
}

#===================================
sub cxns_seeds_str {
#===================================
    my $self = shift;
    join ", ", ( map { $_->stringify } @{ $self->cxns } ),
        @{ $self->seed_nodes };
}

#===================================
sub reset_retries { shift->retries(0) }
sub _max_retries  {2}
#===================================

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::CxnPool - Provides common functionality to the CxnPool implementations

=head1 VERSION

version 3.007007

=head1 DESCRIPTION

See the CxnPool implementations:

=over

=item *

L<OpenSearch::Client::CxnPool::Static>

=item *

L<OpenSearch::Client::CxnPool::Sniff>

=item *

L<OpenSearch::Client::CxnPool::Static::NoPing>

=back

=head1 CONFIGURATION

These configuration options should not be set by the user but are
documented here for completeness.

=head2 C<randomize_cxns>

By default, the order of cxns passed to L</set_cxns()> is randomized
before they are stored.  Set C<randomize_cxns> to a false value to
disable.

=head1 METHODS

=head2 C<cxn_factory()>

    $factory = $cxn_pool->cxn_factory

Returns the L<OpenSearch::Client::Cxn::Factory> object for creating a new
C<$cxn> instance.

=head2 C<logger()>

    $logger = $cxn_pool->logger

Returns the L<OpenSearch::Client::Role::Logger>-based object, which
defaults to L<OpenSearch::Client::Logger::LogAny>.

=head2 C<serializer()>

    $serializer = $cxn_pool->serializer

Returns the L<OpenSearch::Client::Role::Serializer>-based object,
which defaults to L<OpenSearch::Client::Serializer::JSON>.

=head2 C<current_cxn_num()>

    $num = $cxn_pool->current_cxn_num

Returns the current cxn number, which is an offset into
the array of cxns set by L</set_cxns()>.

=head2 C<cxns()>

    \@cxns = $cxn_pool->cxns;

Returns the current list of L<OpenSearch::Client::Role::Cxn>-based
cxn objects as set by L</set_cxns()>.

=head2 C<seed_nodes()>

    \@seed_nodes = $cxn_pool->seed_nodes

Returns the list of C<nodes> originally specified when calling
L<OpenSearch::Client/new()>.

=head2 C<next_cxn_num()>

    $num = $cxn_pool->next_cxn_num;

Returns the number of the next connection, in round-robin fashion.  Updates
the L</current_cxn_num()>.

=head2 C<set_cxns()>

    $cxn_pool->set_cxns(@nodes);

Takes a list of nodes, converts them into L<OpenSearch::Client::Role::Cxn>-based
objects and makes them accessible via L</cxns()>.

=head2 C<request_ok()>

    $cxn_pool->request_ok($cxn);

Called when a request by the specified C<$cxn> object has completed successfully.
Marks the C<$cxn> as live.

=head2 C<request_failed()>

    $should_retry = $cxn_pool->request_failed($cxn,$error);

Called when a request by the specified C<$cxn> object has failed. Returns
C<1> if the request should be retried or C<0> if it shouldn't.

=head2 C<should_retry()>

    $bool = $cxn_pool->should_retry($error);

Examines the error to decide whether the request should be retried or not.
By default, only L<OpenSearch::Client::Error/OpenSearch::Client::Error::Cxn> errors
are retried.

=head2 C<should_mark_dead()>

    $bool = $cxn_pool->should_mark_dead($error);

Examines the error to decide whether the C<$cxn> should be marked as dead or not.
By default, only L<OpenSearch::Client::Error/OpenSearch::Client::Error::Cxn> errors
cause a C<$cxn> to be marked as dead.

=head2 C<cxns_str()>

    $str = $cxn_pool->cxns_str

Returns all L</cxns()> as a string for logging purposes.

=head2 C<cxns_seeds_str()>

    $str = $cxn_pool->cxns_seeeds_str

Returns all L</cxns()> and L</seed_nodes()> as a string for logging purposes.

=head2 C<retries()>

    $retries = $cxn_pool->retries

The number of times the current request has been retried.

=head2 C<reset_retries()>

    $cxn_pool->reset_retries;

Called at the start of a new request to reset the retries count.

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
