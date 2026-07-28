package OpenSearch::Client::Transport::TryCatch;
$OpenSearch::Client::Transport::TryCatch::VERSION = '3.007010';
use Moo;

use URI();
use Time::HiRes qw(time);
use Try::Tiny;
use OpenSearch::Client::Util qw(upgrade_error);
use namespace::clean;

with 'OpenSearch::Client::Role::Is_Sync',
    'OpenSearch::Client::Role::Transport';

#===================================
sub perform_request {
#===================================
    my $self   = shift;
    my $params = $self->tidy_request(@_);
    my $pool   = $self->cxn_pool;
    my $logger = $self->logger;

    my ( $code, $response, $cxn, $error );

    try {
        $cxn = $pool->next_cxn;
        my $start = time();
        $logger->trace_request( $cxn, $params );

        ( $code, $response ) = $cxn->perform_request($params);
        $pool->request_ok($cxn);
        $logger->trace_response( $cxn, $code, $response, time() - $start );
    }
    catch {
        $error = upgrade_error(
            $_,
            {   request     => $params,
                status_code => $code,
                body        => $response
            }
        );
    };

    if ($error) {
        if ( $pool->request_failed( $cxn, $error ) ) {
            $logger->debugf( "[%s] %s", $cxn->stringify, "$error" );
            $logger->info('Retrying request on a new cxn');
            return $self->perform_request($params);
        }

        $logger->trace_error( $cxn, $error );
        $response = undef;
    }
    
    if (wantarray) {
        return( $response, $error );
    } else {
        return ( $response ) ? $response : $error;
    }
    
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Transport::TryCatch - Provides interface between the client class and the OpenSearch cluster

=head1 VERSION

version 3.007010

=head1 DESCRIPTION

This Transport class manages the request cycle. It receives parsed requests
from the (user-facing) client class, and tries to execute the request on a
node in the cluster, retrying a request if necessary.

It returns any errors in response to the request.

This class does L<OpenSearch::Client::Role::Transport> and
L<OpenSearch::Client::Role::Is_Sync>

Specify it as the transport when creating a client instance.

    my $os = OpenSearch::Client->new(
        transport => 'TryCatch',
        ....
    );

Errors are captured and returned.

    my ($response, $error) = $os->call_some_method(%params);
    if( $error ) {
        # $error is an L<OpenSearch::Client::Error> object
        if( $error->is('NoNodes') ) {
            # this error is unrecoverable
            .....
        }
        .....
    }
           
    my $response_or_error = $os->call_some_method(%params);
    
    if($response_or_error->isa('OpenSearch::Client::Error')) {
        .....
    }

=head1 CONFIGURATION

=head2 C<send_body_as_source>

    $os = OpenSearch::Client->new(
        transport => 'TryCatch',
        send_body_as_source => 1,
    );

The body is encoded as JSON and added to the query string as the C<source>
parameter.  This has the advantages for those filtering on request method
but has the disadvantage of being restricted in size.  The limit depends
on the proxies between the client and OpenSearch, but usually is around 4kB.

=head1 METHODS

=head2 C<perform_request()>

Raw requests can be executed using the transport class as follows:

    $result = $os->transport->perform_request(
        method => 'POST',
        path   => '/_search',
        qs     => { from => 0, size => 10 },
        body   => {
            query => {
                match => {
                    title => "OpenSearch clients"
                }
            }
        }
    );

Other than the C<method>, C<path>, C<qs> and C<body> parameters, which
should be self-explanatory, it also accepts:

=over

=item C<ignore>

The HTTP error codes which should be ignored instead of throwing an error,
eg C<404 NOT FOUND>:

    $result = $os->transport->perform_request(
        method => 'GET',
        path   => '/index/type/id'
        ignore => [404],
    );

=item C<serialize>

Whether the C<body> should be serialized in the standard way (as plain
JSON) or using the special I<bulk> format:  C<"std"> or C<"bulk">.

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

