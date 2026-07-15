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

package OpenSearch::Client::Cxn::HTTPTiny;
$OpenSearch::Client::Cxn::HTTPTiny::VERSION = '3.007009';
use Moo;
with 'OpenSearch::Client::Role::Cxn', 'OpenSearch::Client::Role::Is_Sync';

use HTTP::Tiny 0.089 ();
use namespace::clean;

my $Cxn_Error = qr/ Connection.(?:timed.out|re(?:set|fused))
                       | connect:.timeout
                       | Host.is.down
                       | No.route.to.host
                       | temporarily.unavailable
                       /x;

#===================================
sub perform_request {
#===================================
    my ( $self, $params ) = @_;
    my $uri    = $self->build_uri($params);
    my $method = $params->{method};

    my %args;
    if ( defined $params->{data} ) {
        $args{content}                     = $params->{data};
        $args{headers}{'Content-Type'}     = $params->{mime_type};
        $args{headers}{'Content-Encoding'} = $params->{encoding}
            if $params->{encoding};
    }

    my $handle = $self->handle;
    $handle->timeout( $params->{timeout} || $self->request_timeout );

    my $response = $handle->request( $method, "$uri", \%args );

    return $self->process_response(
        $params,                 # request
        $response->{status},     # code
        $response->{reason},     # msg
        $response->{content},    # body
        $response->{headers}     # headers
    );
}

#===================================
sub error_from_text {
#===================================
    local $_ = $_[2];
    return
          /[Tt]imed out/             ? 'Timeout'
        : /Unexpected end of stream/ ? 'ContentLength'
        : /SSL connection failed/    ? 'SSL'
        : /$Cxn_Error/               ? 'Cxn'
        :                              'Request';
}

#===================================
sub _build_handle {
#===================================
    my $self = shift;
    my %args = ( default_headers => $self->default_headers );
    
    if ( $self->is_https ) {
        $args{SSL_options}
            = $self->has_ssl_options
            ? $self->ssl_options
            : { SSL_verify_mode => 0x01 };          
    }
            
    $args{http_proxy}  = $self->http_proxy  if $self->has_http_proxy;
    $args{https_proxy} = $self->https_proxy if $self->has_https_proxy;
    $args{no_proxy}    = $self->no_proxy    if $self->has_no_proxy;
    
    return HTTP::Tiny->new( %args, %{ $self->handle_args } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Cxn::HTTPTiny - A Cxn implementation which uses HTTP::Tiny

=head1 VERSION

version 3.007009

=head1 DESCRIPTION

Provides the default HTTP Cxn class and is based on L<HTTP::Tiny>.
The HTTP::Tiny backend is fast, uses pure Perl, support proxies and https
and provides persistent connections.

This class does L<OpenSearch::Client::Role::Cxn>, whose documentation
provides more information, and L<OpenSearch::Client::Role::Is_Sync>.

=head1 CONFIGURATION

=head2 Inherited configuration

From L<OpenSearch::Client::Role::Cxn>

=over

=item * L<node|OpenSearch::Client::Role::Cxn/"node">

=item * L<max_content_length|OpenSearch::Client::Role::Cxn/"max_content_length">

=item * L<deflate|OpenSearch::Client::Role::Cxn/"gzip">

=item * L<deflate|OpenSearch::Client::Role::Cxn/"deflate">

=item * L<request_timeout|OpenSearch::Client::Role::Cxn/"request_timeout">

=item * L<ping_timeout|OpenSearch::Client::Role::Cxn/"ping_timeout">

=item * L<dead_timeout|OpenSearch::Client::Role::Cxn/"dead_timeout">

=item * L<max_dead_timeout|OpenSearch::Client::Role::Cxn/"max_dead_timeout">

=item * L<sniff_request_timeout|OpenSearch::Client::Role::Cxn/"sniff_request_timeout">

=item * L<sniff_timeout|OpenSearch::Client::Role::Cxn/"sniff_timeout">

=item * L<handle_args|OpenSearch::Client::Role::Cxn/"handle_args">

=item * L<handle_args|OpenSearch::Client::Role::Cxn/"default_qs_params">

=back

=head1 SSL/TLS

L<OpenSearch::Client::Cxn::HTTPTiny> uses L<IO::Socket::SSL> to support
HTTPS.  By default, full verification of the remote host certificate is performed.

If the remote server cannot be verified, an
L<OpenSearch::Client::Error|SSL error> will be thrown.

This behaviour can be changed by passing the C<ssl_options> parameter
with any options passed through to L<IO::Socket::SSL> by L<HTTP::Tiny>.

For example, to perform no validation of the remote host certificate

    use OpenSearch::Client;
    
    my $os = OpenSearch::Client->new(
        nodes => [
            "https://node1.mydomain.com:9200",
            "https://node2.mydomain.com:9200",
        ],
        ssl_options => {
            SSL_verify_mode     => 0x00,
        }
    );

To verify that the cerificate is signed by your own trusted CA
Authority but not verify the hostname 

    use OpenSearch::Client;
    
    my $os = OpenSearch::Client->new(
        nodes => [
            "https://node1.mydomain.com:9200",
            "https://node2.mydomain.com:9200",
        ],
        ssl_options => {
            SSL_verify_mode     => 0x01,
            SSL_verifycn_scheme => 'none',
            SSL_ca_file         => '/path/to/ca_cert.pem',
        }
    );

If you want your client to present its own certificate to the remote
server, then use:

    use OpenSearch::Client;
    
    my $os = OpenSearch::Client->new(
        nodes => [
            "https://node1.mydomain.com:9200",
            "https://node2.mydomain.com:9200",
        ],
        ssl_options => {
            SSL_verify_mode     => 0x01,
            SSL_use_cert        => 1,
            SSL_ca_file         => '/path/to/cacert.pem',
            SSL_cert_file       => '/path/to/client.pem',
            SSL_key_file        => '/path/to/client.pem',
        }
    );

=head1 Proxies

Options for C<http_proxy>, C<https_proxy> and C<no_proxy> can be configured.

    my $os = OpenSearch::Client->new(
        http_proxy  => 'http://192.168.200.250:8888',
        https_proxy => 'http://192.168.200.250:8888',
        no_proxy    => [ '192.168.200.81', '192.168.200.82', '192.168.200.83' ]  
    );

=head1 METHODS

=head2 C<perform_request()>

    ($status,$body) = $self->perform_request({
        # required
        method      => 'GET|HEAD|POST|PUT|DELETE',
        path        => '/path/of/request',
        qs          => \%query_string_params,

        # optional
        data        => $body_as_string,
        mime_type   => 'application/json',
        timeout     => $timeout
    });

Sends the request to the associated OpenSearch node and returns
a C<$status> code and the decoded response C<$body>, or throws an
error if the request failed.

=head2 Inherited methods

From L<OpenSearch::Client::Role::Cxn>

=over

=item * L<scheme()|OpenSearch::Client::Role::Cxn/"scheme()">

=item * L<is_https()|OpenSearch::Client::Role::Cxn/"is_https()">

=item * L<userinfo()|OpenSearch::Client::Role::Cxn/"userinfo()">

=item * L<default_headers()|OpenSearch::Client::Role::Cxn/"default_headers()">

=item * L<max_content_length()|OpenSearch::Client::Role::Cxn/"max_content_length()">

=item * L<build_uri()|OpenSearch::Client::Role::Cxn/"build_uri()">

=item * L<host()|OpenSearch::Client::Role::Cxn/"host()">

=item * L<port()|OpenSearch::Client::Role::Cxn/"port()">

=item * L<uri()|OpenSearch::Client::Role::Cxn/"uri()">

=item * L<is_dead()|OpenSearch::Client::Role::Cxn/"is_dead()">

=item * L<is_live()|OpenSearch::Client::Role::Cxn/"is_live()">

=item * L<next_ping()|OpenSearch::Client::Role::Cxn/"next_ping()">

=item * L<ping_failures()|OpenSearch::Client::Role::Cxn/"ping_failures()">

=item * L<mark_dead()|OpenSearch::Client::Role::Cxn/"mark_dead()">

=item * L<mark_live()|OpenSearch::Client::Role::Cxn/"mark_live()">

=item * L<force_ping()|OpenSearch::Client::Role::Cxn/"force_ping()">

=item * L<pings_ok()|OpenSearch::Client::Role::Cxn/"pings_ok()">

=item * L<sniff()|OpenSearch::Client::Role::Cxn/"sniff()">

=item * L<process_response()|OpenSearch::Client::Role::Cxn/"process_response()">

=back

=head1 SEE ALSO

=over

=item * L<OpenSearch::Client::Role::Cxn>

=item * L<OpenSearch::Client::Cxn::LWP>

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
