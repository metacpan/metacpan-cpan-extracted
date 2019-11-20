package Pcore::API::Cloudflare;

use Pcore -const, -class, -res;

has email => ( required => 1 );
has key   => ( required => 1 );

has max_threads => 10;

has _headers   => ( init_arg => undef );
has _semaphore => sub ($self) { Coro::Semaphore->new( $self->{max_threads} ) }, is => 'lazy';

const our $API_VER => 4;

sub _req ( $self, $method, $path, $query = undef, $data = undef ) {

    # block thread
    my $guard = $self->{max_threads} && $self->_semaphore->guard;

    my $url = qq[https://api.cloudflare.com/client/v$API_VER/$path];

    $url .= '?' . P->data->to_uri($query) if defined $query;

    my $res = P->http->request(
        method  => $method,
        url     => $url,
        headers => $self->{_headers} //= [
            'X-Auth-Email' => $self->{email},
            'X-Auth-Key'   => $self->{key},
            'Content-Type' => 'application/json',
        ],
        data => defined $data ? P->data->to_json($data) : undef,
    );

    if ($res) {
        return res $res, P->data->from_json( $res->{data} );
    }
    else {
        return res $res, $res->{data} ? P->data->from_json( $res->{data} ) : ();
    }
}

# https://api.cloudflare.com/#zone-list-zones
sub zones ( $self ) {
    my $res = $self->_req( 'GET', '/zones' );

    $res->{data} = { map { $_->{name} => $_ } $res->{data}->{result}->@* } if $res;

    return $res;
}

# https://api.cloudflare.com/#zone-create-zone
sub zone_create ( $self, $domain, $account_id ) {
    return $self->_req(
        'POST', '/zones', undef,
        {   name       => $domain,
            account    => { id => $account_id, },
            jump_start => \1,
            type       => 'full',
        }
    );
}

# https://api.cloudflare.com/#zone-delete-zone
sub zone_remove ( $self, $id ) {
    return $self->_req( 'DELETE', "/zones/$id" );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Cloudflare

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
