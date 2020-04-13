package Pcore::API::moz;

use Pcore -class, -res;
use Pcore::Util::Scalar qw [is_plain_arrayref];
use Pcore::Util::Data qw[to_b64 to_uri to_json from_json];

has api_user => ( required => 1 );
has api_key  => ( required => 1 );
has free         => 0;     # free or paid api
has max_threads  => 5;     # use 1 thread for free moz api account
has use_interval => 0;     # use interval between requests, used for moz free api account
has interval     => 10;    # use interval between requests, used for moz free api account

has _auth        => ( is => 'lazy' );
has _semaphore   => sub ($self) { Coro::Semaphore->new( $self->{max_threads} ) }, is => 'lazy';
has _last_req_ts => ();

# https://moz.com/help/links-api, click on "making calls" to open api endpoints

sub BUILD ( $self, $args ) {
    if ( $self->{free} ) {
        $self->{max_threads}  = 1;
        $self->{use_interval} = 1;
    }

    return;
}

sub _build__auth ( $self) {
    return 'Basic ' . to_b64( "$self->{api_user}:$self->{api_key}", $EMPTY );
}

# https://moz.com/help/links-api/making-calls/anchor-text-metrics
# scope: page, subdomain, root_domain
# limit: 1-50
sub get_anchor_text ( $self, $target, $scope, %args ) {
    my $res = $self->_req(
        'anchor_text',
        {   target => $target,
            scope  => $scope,
            $args{limit} ? ( limit => $args{limit} ) : (),
        }
    );

    return $res;
}

# https://moz.com/help/links-api/making-calls/final-redirect
# TODO
sub get_final_redirect ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/global-top-pages
# TODO
sub get_global_top_pages ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/global-top-root-domains
# TODO
sub get_global_top_root_domains ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/index-metadata
# TODO
sub get_index_metadata ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/link-intersect
# TODO
sub get_link_intersect ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/link-status
# TODO
sub get_link_status ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/linking-root-domains
# TODO
sub get_linking_root_domains ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/link-metrics
# TODO
sub get_links ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/top-pages-metrics
# TODO
sub get_top_pages ($self) {
    ...;
}

# https://moz.com/help/links-api/making-calls/url-metrics
# urls - up to 50 urls
# da = domain_authority - Domain Authority, a normalized 100-point score representing the likelihood of a domain to rank well in search engine results
# pa = page_authority - Page Authority, a normalized 100-point score representing the likelihood of a page to rank well in search engine results
# fmrp = fmrp - DEPRECATED
sub get_url_metrics ( $self, $url, %args ) {
    my $res = $self->_req( 'url_metrics', { targets => is_plain_arrayref $url ? $url : [$url], } );

    return $res;
}

# https://moz.com/help/links-api/making-calls/usage-data
# TODO
sub get_usage_data ($self) {
    ...;
}

sub _req ( $self, $endpoint, $params ) {
    my $guard = $self->{max_threads} && $self->_semaphore->guard;

    if ( $self->{use_interval} && ( my $timeout = $self->{_last_req_ts} + $self->{interval} - time ) > 0 ) {
        Coro::sleep $timeout;
    }

    my $res = P->http->post(
        "https://lsapi.seomoz.com/v2/$endpoint",
        headers => [    #
            Authorization => $self->_auth,
        ],
        data => to_json $params,
    );

    if ($res) {
        my $data = from_json $res->{data};

        $res = res 200, $data;
    }
    elsif ( $res->{data} ) {
        my $data = from_json $res->{data};

        $res = res [ 500, $data->{message} ];
    }

    $self->{_last_req_ts} = time;

    return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 51, 57, 63, 69, 75,  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |      | 81, 87, 93, 99, 116  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::moz

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
