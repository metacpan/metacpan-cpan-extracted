package Pcore::API::Majestic v0.12.0;

use Pcore -dist, -class, -const, -result, -export => { CONST => [qw[$MAJESTIC_INDEX_FRESH $MAJESTIC_INDEX_HISTORIC]] };
use IO::Uncompress::Unzip qw[];

const our $MAJESTIC_INDEX_FRESH    => 1;
const our $MAJESTIC_INDEX_HISTORIC => 2;

has username => ( is => 'ro', isa => Str );
has password => ( is => 'ro', isa => Str );

has api_key              => ( is => 'ro', isa => Maybe [Str] );    # direct access to the API, access is restricted by IP address
has openapp_access_token => ( is => 'ro', isa => Maybe [Str] );    # OpenApp access, user key, identify user
has openapp_private_key  => ( is => 'ro', isa => Maybe [Str] );    # OpenApp access, application vendor key, identify application
has bind_ip              => ( is => 'ro', isa => Maybe [Str] );

has _cookies        => ( is => 'ro', isa => HashRef,  init_arg => undef );
has _cookies_time   => ( is => 'ro', isa => Int,      init_arg => undef );
has _login_requests => ( is => 'ro', isa => ArrayRef, init_arg => undef );

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

# NOTE max. 100k domains
sub bulk_check ( $self, $domains, $cb ) {

    # login
    $self->_login(
        sub ($res) {
            if ( !$res ) {
                $cb->($res);

                return;
            }

            my $cookies = $res->{data};

            my $job_id = P->uuid->str;

            my $body = qq[-----------------------------3733385012218\r\nContent-Disposition: form-data; name=\"file\"; filename="$job_id"\r\nContent-Type: text/plain\r\n\r\n@{[ join( $LF, $domains->@*) . $LF ]}\r\n-----------------------------3733385012218\r\nContent-Disposition: form-data; name="ajaxLoadUrl"\r\n\r\n/reports/downloads/confirm-file-upload/backlinksAjax\r\n-----------------------------3733385012218\r\nContent-Disposition: form-data; name="fileType"\r\n\r\nSingleColumn\r\n-----------------------------3733385012218\r\nContent-Disposition: form-data; name="IndexDataSource"\r\n\r\nF\r\n-----------------------------3733385012218--\r\n];

            # send domains
            P->http->post(
                'https://majestic.com/reports/bulk-backlinks-upload',
                useragent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0',
                cookies   => $cookies,
                headers   => {
                    CONTENT_TYPE => 'multipart/form-data; boundary=---------------------------3733385012218',
                    REFERER      => 'https://majestic.com/reports/bulk-backlink-checker',
                },
                body      => $body,
                on_finish => sub ($res) {
                    if ( !$res ) {
                        $cb->( result [ 500, 'Send domains error' ] );
                    }
                    elsif ( $res->decoded_body->$* =~ /fileupload_uid=([[:xdigit:]-]+)/sm ) {
                        my $uid = $1;

                        my $params = {
                            fileupload_uid       => $uid,
                            addFileToRecrawlList => 'false',
                            index_data_source    => 'Fresh',
                            tool                 => 'BacklinkChecker',
                        };

                        P->http->get(
                            'https://majestic.com/reports/downloads/accept-file-upload-charges?' . P->data->to_uri($params),
                            useragent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0',
                            cookies   => $cookies,
                            headers   => {                                                                                   #
                                REFERER => "https://majestic.com/reports/downloads/confirm-file-upload?tool=BacklinkChecker&fileupload_uid=$uid",
                            },
                            on_finish => sub ($res) {
                                if ( !$res ) {
                                    $cb->( result [ $res->status, $res->reason ] );
                                }
                                else {
                                    if ( $res->decoded_body->$* =~ /$uid/sm ) {
                                        $cb->( result 200, $job_id );
                                    }
                                    else {
                                        $cb->( result [ 500, 'Unknown confirmation error' ] );
                                    }
                                }

                                return;
                            }
                        );
                    }
                    else {
                        $cb->( result [ 500, 'Send domains error - no job UID returned' ] );
                    }

                    return;
                }
            );

            return;
        }
    );

    return;
}

sub bulk_check_result ( $self, $id, $mapping, $cb ) {

    # login
    $self->_login(
        sub ($res) {
            if ( !$res ) {
                $cb->($res);

                return;
            }

            my $cookies = $res->{data};

            P->http->get(
                'https://majestic.com/reports/downloads',
                useragent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0',
                cookies   => $cookies,
                on_finish => sub ($res) {
                    if ( !$res ) {
                        $cb->( result [ 500, 'Get jobs list error' ] );

                        return;
                    }
                    else {
                        if ( $res->decoded_body->$* =~ /\Q$id\E/sm ) {
                            if ( $res->decoded_body->$* =~ /<a href="\/reports\/downloads\/([[:xdigit:]-]+)">\s+\Q$id\E/sm ) {
                                my $file_id = $1;

                                P->http->get(
                                    "https://majestic.com/reports/downloads/$file_id",
                                    useragent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0',
                                    cookies   => $cookies,
                                    on_finish => sub ($res) {
                                        if ( !$res ) {
                                            $cb->( result [ 500, 'Job download error' ] );
                                        }
                                        else {
                                            IO::Uncompress::Unzip::unzip( $res->body, \my $data );

                                            my @lines = split "\n", $data;

                                            my $header = [ map { $mapping->{$_} || '_' } map { s/"//smg; $_ } split /,/sm, shift @lines ];    ## no critic qw[ControlStructures::ProhibitMutatingListFunctions]

                                            my $items;

                                            for my $line (@lines) {
                                                my $item->@{ $header->@* } = map { s/"//smg; $_ } split /,/sm, $line;                         ## no critic qw[ControlStructures::ProhibitMutatingListFunctions]

                                                delete $item->{_};

                                                push $items->@*, $item;
                                            }

                                            $cb->( result 200, $items );
                                        }

                                        return;
                                    }
                                );
                            }
                            else {
                                $cb->( result [ 400, 'Job not ready' ] );
                            }
                        }
                        else {
                            $cb->( result [ 404, 'Job not found' ] );
                        }
                    }

                    return;
                }
            );
        }
    );

    return;
}

sub _login ( $self, $cb ) {

    # login is valid for 1 day
    if ( $self->{_cookies} && $self->{_cookies_time} + 60 * 60 * 24 > time ) {
        $cb->( result 200, $self->{_cookies} );
    }
    else {
        push $self->{_login_requests}->@*, $cb;

        return if $self->{_login_requests}->@* > 1;

        state $on_finish = sub ( $self, $res ) {
            while ( my $cb = shift $self->{_login_requests}->@* ) {
                AE::postpone { $cb->($res) };
            }

            return;
        };

        my $cookies = {};

        P->http->post(
            'https://majestic.com/account/login',
            useragent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0',
            cookies   => $cookies,
            headers   => { CONTENT_TYPE => 'application/x-www-form-urlencoded' },
            body      => P->data->to_uri( { EmailAddress => $self->{username}, Password => $self->{password}, RememberMe => 1 } ),
            on_finish => sub ($res) {
                if ( !$res ) {
                    undef $self->{_cookies};

                    $on_finish->( $self, result [ 500, 'Login error' ] );
                }
                elsif ( $res->decoded_body->$* =~ /in a lot today/sm ) {
                    undef $self->{_cookies};

                    $on_finish->( $self, result [ 500, 'Login error - captcha' ] );
                }
                else {
                    $self->{_cookies} = $cookies;

                    $self->{_cookies_time} = time;

                    $on_finish->( $self, result 200, $cookies );
                }

                return;
            }
        );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 292, 297             | BuiltinFunctions::ProhibitComplexMappings - Map blocks should have a single statement                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 290                  | BuiltinFunctions::ProhibitStringySplit - String delimiter used with "split"                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Majestic

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
