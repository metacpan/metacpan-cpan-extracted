package Pcore::API::twocaptcha;

use Pcore -class, -res, -const;

has api_key  => ( required => 1 );
has api_host => ( required => 1 );
has proxy    => ();

const our $RECHECK_INTERVAL => 3;

sub normal_captcha ( $self, $img, %args ) {
    return $self->_resolve(
        'POST', undef,
        [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
        P->data->to_uri( {
            %args,
            key    => $self->{api_key},
            method => 'base64',
            body   => P->data->to_b64( $img->$* ),
        } )
    );
}

sub recaptcha_v2 ( $self, $site_key, $page_url ) {
    my $q = P->data->to_uri( {
        key       => $self->{api_key},
        method    => 'userrecaptcha',
        googlekey => $site_key,
        pageurl   => $page_url,
    } );

    my $res = P->http->get( "$self->{api_host}/in.php?$q", proxy => $self->{proxy}, );

    return $res if !$res;

    my ( $status, $id ) = split /[|]/sm, $res->{data}->$*;

    return res 400 if $status ne 'OK';

    return $self->_get_result($id);
}

sub _resolve ( $self, $method, $params, $headers, $data ) {
    my $res = P->http->request(
        method  => $method,
        url     => "$self->{api_host}/in.php" . ( $params ? '?' . P->data->to_uri($params) : $EMPTY ),
        proxy   => $self->{proxy},
        headers => $headers,
        data    => $data,
    );

    return $res if !$res;

    my ( $status, $id ) = split /[|]/sm, $res->{data}->$*;

    return res 400 if $status ne 'OK';

    return $self->_get_result($id);
}

sub _get_result ( $self, $id ) {
    my $q = P->data->to_uri( {
        key    => $self->{api_key},
        action => 'get',
        id     => $id,
        json   => 0,
    } );

    my $url = P->uri( "$self->{api_host}/res.php?$q", proxy => $self->{proxy} );

    my $res;

    while () {
        Coro::sleep $RECHECK_INTERVAL;

        $res = P->http->get($url);

        last if !$res;

        my ( $status, $result ) = split /[|]/sm, $res->{data}->$*;

        say "GET CAPTCHA RESULT: $status, " . ( $result // '-' );

        next if $status eq 'CAPCHA_NOT_READY';

        if ( $status eq 'OK' ) {
            $res = res 200, $result;
        }
        else {
            $res = res [ 500, $status ];
        }

        last;
    }

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::twocaptcha

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
