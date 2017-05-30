package Pcore::API::Majestic v0.11.1;

use Pcore -dist, -class, -const, -result, -export => { CONST => [qw[$MAJESTIC_INDEX_FRESH $MAJESTIC_INDEX_HISTORIC]] };

const our $MAJESTIC_INDEX_FRESH    => 1;
const our $MAJESTIC_INDEX_HISTORIC => 2;

has api_key              => ( is => 'ro', isa => Maybe [Str] );    # direct access to the API, access is restricted by IP address
has openapp_access_token => ( is => 'ro', isa => Maybe [Str] );    # OpenApp access, user key, identify user
has openapp_private_key  => ( is => 'ro', isa => Maybe [Str] );    # OpenApp access, application vendor key, identify application
has bind_ip              => ( is => 'ro', isa => Maybe [Str] );

sub get_subscription_info ( $self, $cb ) {
    my $url_params = {
        cmd        => 'GetSubscriptionInfo',
        datasource => 'historic',
    };

    $self->_request( $url_params, $cb );

    return;
}

# https://developer-support.majestic.com/api/commands/get-index-item-info.shtml
sub get_index_item_info ( $self, $domains, $datasource, $failover, $cb ) {
    die q[Maximum items number is 100] if $domains->@* > 100;

    my $url_params = {
        cmd                        => 'GetIndexItemInfo',
        datasource                 => $datasource == $MAJESTIC_INDEX_FRESH ? 'fresh' : 'historic',
        EnableResourceUnitFailover => $failover,
        items                      => scalar $domains->@*,
    };

    for my $i ( 0 .. $domains->$#* ) {
        $url_params->{ 'item' . $i } = $domains->[$i];
    }

    $self->_request(
        $url_params,
        sub ($res) {
            if ( $res->is_success ) {
                my $json = delete $res->{data};

                for my $item ( $json->{DataTables}->{Results}->{Data}->@* ) {
                    $res->{data}->{ $domains->[ $item->{ItemNum} ] } = $item;
                }
            }

            $cb->($res);

            return;
        }
    );

    return;
}

# https://developer-support.majestic.com/api/commands/get-back-link-data.shtml
sub get_backlink_data ( $self, $domain, $params, $cb ) {
    my $url_params = {
        cmd                        => 'GetBackLinkData',
        datasource                 => 'fresh',
        item                       => $domain,
        Count                      => 100,                 # Number of results to be returned back. Max. 50_000
        Mode                       => 0,
        ShowDomainInfo             => 0,
        MaxSourceURLsPerRefDomain  => -1,
        MaxSameSourceURLs          => -1,
        RefDomain                  => undef,
        FilterTopic                => undef,
        FilterTopicsRefDomainsMode => 0,
        UsePrefixScan              => 0,
        defined $params ? $params->%* : (),
    };

    $self->_request(
        $url_params,
        sub ($res) {
            $cb->($res);

            return;
        }
    );

    return;
}

# https://developer-support.majestic.com/api/commands/get-anchor-text.shtml
sub get_anchor_text ( $self, $domain, $params, $cb ) {
    my $url_params = {
        cmd                  => 'GetAnchorText',
        datasource           => 'fresh',
        item                 => $domain,
        Count                => 10,                # Number of results to be returned back. Max. 1_000
        TextMode             => 0,
        Mode                 => 0,
        FilterAnchorText     => undef,
        FilterAnchorTextMode => 0,
        FilterRefDomain      => undef,
        UsePrefixScan        => 0,
        defined $params ? $params->%* : (),
    };

    $self->_request(
        $url_params,
        sub ($res) {
            $cb->($res);

            return;
        }
    );

    return;
}

sub _request ( $self, $url_params, $cb ) {
    if ( $self->api_key ) {
        $url_params->{app_api_key} = $self->api_key;
    }
    elsif ( $self->openapp_private_key && $self->openapp_access_token ) {
        $url_params->{accesstoken} = $self->openapp_access_token;

        $url_params->{privatekey} = $self->openapp_private_key;
    }
    else {
        die q["api_key" or "openapp_private_key" and "openapp_access_token" are missed];
    }

    my $url = 'http://api.majestic.com/api/json?' . P->data->to_uri($url_params);

    P->http->get(
        $url,
        timeout    => 60,
        persistent => 30,
        bind_ip    => $self->bind_ip,
        on_finish  => sub ($res) {
            if ( !$res ) {
                $cb->( result [ $res->status, $res->reason ] );
            }
            else {
                my $json = eval { P->data->from_json( $res->body->$* ); };

                if ($@) {
                    $cb->( result [ 500, 'Error decoding response' ] );
                }
                elsif ( $json->{Code} ne 'OK' ) {
                    $cb->( result [ 400, $json->{ErrorMessage} ] );
                }
                else {
                    $cb->( result 200, $json );
                }
            }

            return;
        },
    );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Majestic

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
