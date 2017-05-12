package Pcore::API::Moz::Account;

use Pcore -class, -result, -const;
use Pcore::Util::Data qw[to_b64 to_uri to_json from_json];
use Pcore::Util::Digest qw[hmac_sha1];
use Pcore::HTTP::CookieJar;

use overload    #
  q[""] => sub {
    return $_[0]->{id};
  },
  fallback => undef;

has moz => ( is => 'ro', isa => InstanceOf ['Pcore::API::Moz'], required => 1 );
has id  => ( is => 'ro', isa => Str, required => 1 );
has key => ( is => 'ro', isa => Str, required => 1 );

has _cookie_jar => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::CookieJar'], default => sub { Pcore::HTTP::CookieJar->new }, init_arg => undef );

has next_req_ts => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );

const our $REQUEST_INTERVAL => 10;    # interval between requests, in seconds

sub is_ready ($self) {
    if ( $self->{next_req_ts} <= time ) {
        return 1;
    }

    return 0;
}

sub get_url_metrics ( $self, $domains, $metric, $cb ) {
    my $url_params = {
        AccessID => $self->{id},
        Expires  => time + $self->{moz}->{api_expires},
        Cols     => $metric,
    };

    $url_params->{Signature} = to_b64 hmac_sha1( $url_params->{AccessID} . $LF . $url_params->{Expires}, $self->{key} );

    my $url = 'https://lsapi.seomoz.com/linkscape/url-metrics/?' . to_uri $url_params;

    $self->{next_req_ts} = time + $REQUEST_INTERVAL;

    my $req = sub ($proxy) {
        P->http->post(
            $url,
            timeout    => 180,
            body       => to_json($domains),
            persistent => 0,
            proxy      => $proxy,
            useragent  => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0',
            cookie_jar => $self->{_cookie_jar},
            on_finish  => sub ($res) {
                my $api_res;

                if ( $res->status != 200 ) {
                    $api_res = result [ $res->status, $res->reason ];
                }
                else {
                    my $json = eval { from_json $res->body->$* };

                    if ($@) {
                        $api_res = result [ 999, 'Invalid JSON body' ];
                    }
                    else {
                        $api_res = result 200;

                        for my $i ( 0 .. $domains->$#* ) {
                            $api_res->{data}->{ $domains->[$i] } = $json->[$i];
                        }
                    }
                }

                $cb->($api_res);

                return;
            },
        );

        return;
    };

    if ( $self->{moz}->{proxy_pool} ) {
        $self->{moz}->{proxy_pool}->get_slot( $url, $req );
    }
    else {
        $req->(undef);
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Moz::Account

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
