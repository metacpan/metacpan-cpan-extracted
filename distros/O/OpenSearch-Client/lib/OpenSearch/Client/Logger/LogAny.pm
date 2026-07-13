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

package OpenSearch::Client::Logger::LogAny;
$OpenSearch::Client::Logger::LogAny::VERSION = '3.007008';
use Moo;
with 'OpenSearch::Client::Role::Logger';
use OpenSearch::Client::Util qw(parse_params to_list);
use namespace::clean;

use Log::Any 1.02 ();
use Log::Any::Adapter();

#===================================
sub _build_log_handle {
#===================================
    my $self = shift;
    if ( my @args = to_list( $self->log_to ) ) {
        Log::Any::Adapter->set( { category => $self->log_as }, @args );
    }
    Log::Any->get_logger( category => $self->log_as );
}

#===================================
sub _build_trace_handle {
#===================================
    my $self = shift;
    if ( my @args = to_list( $self->trace_to ) ) {
        Log::Any::Adapter->set( { category => $self->trace_as }, @args );
    }
    Log::Any->get_logger( category => $self->trace_as );
}

#===================================
sub _build_deprecate_handle {
#===================================
    my $self = shift;
    if ( my @args = to_list( $self->deprecate_to ) ) {
        Log::Any::Adapter->set( { category => $self->deprecate_as }, @args );
    }
    Log::Any->get_logger(
        default_adapter => 'Stderr',
        category        => $self->deprecate_as
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Logger::LogAny - A Log::Any-based Logger implementation

=head1 VERSION

version 3.007008

=head1 DESCRIPTION

L<OpenSearch::Client::Logger::LogAny> provides event logging and the tracing
of request/response conversations with OpenSearch nodes via the
L<Log::Any> module.

I<Logging> refers to log events, such as node failures, pings, sniffs, etc,
and should be enabled for monitoring purposes.

I<Tracing> refers to the actual HTTP requests and responses sent
to OpenSearch nodes.  Tracing can be enabled for debugging purposes,
or for generating a pretty-printed C<curl> script which can be used for
reporting problems.

I<Deprecations> refers to deprecation warnings returned by OpenSearch.
Deprecations are logged to STDERR by default.

=head1 CONFIGURATION

Logging and tracing can be enabled using L<Log::Any::Adapter>, or by
passing options to L<OpenSearch::Client/new()>.

=head2 USING LOG::ANY::ADAPTER

Send all logging and tracing to C<STDERR>:

    use Log::Any::Adapter qw(Stderr);
    use OpenSearch::Client;
    my $os = OpenSearch::Client->new;

Send logging and deprecations to a file, and tracing to Stderr:

    use Log::Any::Adapter();
    Log::Any::Adapter->set(
        { category => 'opensearch.event' },
        'File',
        '/path/to/file.log'
    );
    Log::Any::Adapter->set(
        { category => 'opensearch.trace' },
        'Stderr'
    );
    Log::Any::Adapter->set(
        { category => 'opensearch.deprecation' },
        'File',
        '/path/to/deprecations.log'
    );

    use OpenSearch::Client;
    my $os = OpenSearch::Client->new;

=head2 USING C<log_to>, C<trace_to> AND C<deprecate_to>

Send all logging and tracing to C<STDERR>:

    use OpenSearch::Client;
    my $os = OpenSearch::Client->new(
        log_to   => 'Stderr',
        trace_to => 'Stderr',
        deprecate_to => 'Stderr'  # default
    );

Send logging and deprecations to a file, and tracing to Stderr:

    use OpenSearch::Client;
    my $os = OpenSearch::Client->new(
        log_to       => ['File', '/path/to/file.log'],
        trace_to     => 'Stderr',
        deprecate_to => ['File', '/path/to/deprecations.log'],
    );

See L<Log::Any::Adapter> for more.

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

