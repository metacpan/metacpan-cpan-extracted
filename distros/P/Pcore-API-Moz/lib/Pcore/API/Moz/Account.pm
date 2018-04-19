package Pcore::API::Moz::Account;

use Pcore -class, -res, -const;
use Pcore::Util::Data qw[to_b64 to_uri to_json from_json];
use Pcore::Util::Digest qw[hmac_sha1];

use overload    #
  q[""] => sub {
    return $_[0]->{id};
  },
  fallback => undef;

has moz => ( is => 'ro', isa => InstanceOf ['Pcore::API::Moz'], required => 1 );
has id  => ( is => 'ro', isa => Str,                            required => 1 );
has key => ( is => 'ro', isa => Str,                            required => 1 );

has _cookies => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

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

    my $request = sub ($proxy) {
        P->http->post(
            $url,
            persistent      => 30,
            connect_timeout => 15,
            timeout         => 60,
            body            => to_json($domains),
            useragent       => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0',
            cookies         => $self->{_cookies},
            proxy           => $proxy,
            sub ($res) {
                if ( !$res ) {
                    $cb->( res [ $res->{status}, $res->{reason} ] );
                }
                else {
                    my $json = eval { from_json $res->{body}->$* };

                    if ($@) {
                        $cb->( res [ 500, 'Invalid JSON body' ] );
                    }
                    else {
                        my $data;

                        for my $i ( 0 .. $domains->$#* ) {
                            $data->{ $domains->[$i] } = $json->[$i];
                        }

                        $cb->( res 200, $data );
                    }
                }

                return;
            },
        );

        return;
    };

    if ( my $proxy_pool = $self->{moz}->{proxy_pool} ) {
        $self->util->proxy_pool->get_slot(
            $url->{url},
            sub ($proxy) {
                $request->($proxy);
            }
        );
    }
    else {
        $request->(undef);
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
