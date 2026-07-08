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

package OpenSearch::Client::Role::Logger;
$OpenSearch::Client::Role::Logger::VERSION = '3.007006';
use Moo::Role;

use URI();
use Try::Tiny;
use OpenSearch::Client::Util qw(new_error);
use namespace::clean;

has 'serializer'   => ( is => 'ro', required => 1 );
has 'log_as'       => ( is => 'ro', default  => 'opensearch.event' );
has 'trace_as'     => ( is => 'ro', default  => 'opensearch.trace' );
has 'deprecate_as' => ( is => 'ro', default  => 'opensearch.deprecation' );
has 'log_to'       => ( is => 'ro' );
has 'trace_to'     => ( is => 'ro' );
has 'deprecate_to' => ( is => 'ro' );

has 'trace_handle' => (
    is      => 'lazy',
    handles => [qw( trace tracef is_trace)]
);

has 'log_handle' => (
    is      => 'lazy',
    handles => [ qw(
            debug       debugf      is_debug
            info        infof       is_info
            warning     warningf    is_warning
            error       errorf      is_error
            critical    criticalf   is_critical
            )
    ]
);

has 'deprecate_handle' => ( is => 'lazy' );

#===================================
sub throw_error {
#===================================
    my ( $self, $type, $msg, $vars ) = @_;
    my $error = new_error( $type, $msg, $vars );
    $self->error($error);
    die $error;
}

#===================================
sub throw_critical {
#===================================
    my ( $self, $type, $msg, $vars ) = @_;
    my $error = new_error( $type, $msg, $vars );
    $self->critical($error);
    die $error;
}

#===================================
sub trace_request {
#===================================
    my ( $self, $cxn, $params ) = @_;
    return unless $self->is_trace;

    my $uri = URI->new( 'http://localhost:9200' . $params->{path} );
    my %qs = ( %{ $params->{qs} }, pretty => "true" );
    $uri->query_form( [ map { $_, $qs{$_} } sort keys %qs ] );

    my $body
        = $params->{serialize} eq 'std'
        ? $self->serializer->encode_pretty( $params->{body} )
        : $params->{data};

    my $content_type = '';
    if ( defined $body ) {
        $body =~ s/'/\\u0027/g;
        $body         = " -d '\n$body'\n";
        $content_type = '-H "Content-type: ' . $params->{mime_type} . '" ';
    }
    else { $body = "\n" }

    my $msg = sprintf(
        "# Request to: %s\n"           #
            . "curl %s-X%s '%s'%s",    #
        $cxn->stringify,
        $content_type,
        $params->{method},
        $uri,
        $body
    );

    $self->trace($msg);
}

#===================================
sub trace_response {
#===================================
    my ( $self, $cxn, $code, $response, $took ) = @_;
    return unless $self->is_trace;

    my $body = $self->serializer->encode_pretty($response) || "\n";
    $body =~ s/^/# /mg;

    my $msg = sprintf(
        "# Response: %s, Took: %d ms\n%s",    #
        $code, $took * 1000, $body
    );

    $self->trace($msg);
}

#===================================
sub trace_error {
#===================================
    my ( $self, $cxn, $error ) = @_;
    return unless $self->is_trace;

    my $body
        = $self->serializer->encode_pretty( $error->{vars}{body} || "\n" );
    $body =~ s/^/# /mg;

    my $msg
        = sprintf( "# ERROR: %s %s\n%s", ref($error), $error->{text}, $body );

    $self->trace($msg);
}

#===================================
sub trace_comment {
#===================================
    my ( $self, $comment ) = @_;
    return unless $self->is_trace;
    $comment =~ s/^/# *** /mg;
    chomp $comment;
    $self->trace("$comment\n");
}

#===================================
sub deprecation {
#===================================
    my $self = shift;

    $self->deprecate_handle->warnf( "[DEPRECATION] %s - In request: %s", @_ );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Role::Logger - Provides common functionality to Logger implementations

=head1 VERSION

version 3.007006

=head1 DESCRIPTION

This role provides common functionality to Logger implementations, to enable
the logging of events and the tracing of request-response conversations
with OpenSearch nodes.

See L<OpenSearch::Client::Logger::LogAny> for the default implementation.

=head1 CONFIGURATION

=head2 C<log_to>

Parameters passed to C<log_to> are used by L<OpenSearch::Client::Role::Logger>
implementations to setup the L</log_handle()>.  See
L<OpenSearch::Client::Logger::LogAny> for details.

=head2 C<log_as>

By default, events emitted by L</debug()>, L</info()>, L</warning()>,
L</error()> and L</critical()> are logged to the L</log_handle()> under the
category C<"opensearch.event">, which can be configured with C<log_as>.

=head2 C<trace_to>

Parameters passed to C<trace_to> are used by L<OpenSearch::Client::Role::Logger>
implementations to setup the L</trace_handle()>. See
L<OpenSearch::Client::Logger::LogAny> for details.

=head2 C<trace_as>

By default, trace output emitted by L</trace_request()>, L</trace_response()>,
L</trace_error()> and L</trace_comment()> are logged under the category
C<opensearch.trace>, which can be configured with C<trace_as>.

=head2 C<deprecate_to>

Parameters passed to C<deprecate_to> are used by L<OpenSearch::Client::Role::Logger>
implementations to setup the L</deprecate_handle()>.  See
L<OpenSearch::Client::Logger::LogAny> for details.

=head2 C<deprecate_as>

By default, events emitted by L</deprecation()> are logged to the
L</deprecate_handle()> under the
category C<"opensearch.deprecation">, which can be configured with C<deprecate_as>.

=head1 METHODS

=head2 C<log_handle()>

Returns an object which can handle the methods:
C<debug()>, C<debugf()>, C<is_debug()>, C<info()>, C<infof()>, C<is_info()>,
C<warning()>, C<warningf()>, C<is_warning()>, C<error()>, C<errorf()>,
C<is_error()>, C<critical()>, C<criticalf()> and  C<is_critical()>.

=head2 C<trace_handle()>

Returns an object which can handle the methods:
C<trace()>, C<tracef()> and C<is_trace()>.

=head2 C<deprecate_handle()>

Returns an object which can handle the C<warnf()> method.

=head2 C<trace_request()>

    $logger->trace_request($cxn,\%request);

Accepts a Cxn object and request parameters and logs them if tracing is
enabled.

=head2 C<trace_response()>

    $logger->trace_response($cxn,$code,$response,$took);

Logs a successful HTTP response, where C<$code> is the HTTP status code,
C<$response> is the HTTP body and C<$took> is the time the request
took in seconds

=head2 C<trace_error()>

    $logger->trace_error($cxn,$error);

Logs a failed HTTP response, where C<$error> is an L<OpenSearch::Client::Error>
object.

=head2 C<trace_comment()>

    $logger->trace_comment($comment);

Used to insert debugging comments into trace output.

=head2 C<deprecation()>

    $logger->deprecation($warning,$request)

Issues a deprecation warning to the deprecation logger.

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
