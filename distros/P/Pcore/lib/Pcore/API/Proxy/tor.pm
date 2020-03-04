package Pcore::API::Proxy::tor;

use Pcore -const, -class;

with qw[Pcore::API::Proxy];

has control_password => $EMPTY;

has is_socks  => 1;
has is_socks5 => 1;

has _control_uri => ( init_arg => undef );

# tor://
# tor://127.0.0.1
# tor://127.0.0.1:9050
# tor://?control_port=9051&control_password=123

const our $DEFAULT_HOST         => '127.0.0.1';
const our $DEFAULT_PORT         => 9050;
const our $DEFAULT_CONTROL_PORT => 9051;

around new => sub ( $orig, $self, $uri ) {
    $self = $self->$orig;

    if ( !( my $host = $uri->{host} ) ) {
        $self->{uri} = P->uri("//$DEFAULT_HOST:$DEFAULT_PORT");
    }
    else {
        $self->{uri} = P->uri( "//$host:" . ( $uri->{port} || 9050 ) );
    }

    $self->set_control_port( $uri->query_params->{control_port} || $DEFAULT_CONTROL_PORT );

    if ( my $control_password = $uri->query_params->{control_password} ) {
        $self->{control_password} = $control_password;
    }

    return $self;
};

sub set_control_port ( $self, $port ) {
    if ( !$port ) {
        undef $self->{_control_uri};
    }
    else {
        $self->{_control_uri} = P->uri("//$self->{uri}->{host}:$port");
    }

    return;
}

sub new_ip ( $self, @ ) {
    my $control_uri = $self->{_control_uri};

    return if !$control_uri;

    my $h = P->handle($control_uri);
    return if !$h;

    $h->write(qq[AUTHENTICATE "$self->{control_password}"\r\nSIGNAL NEWNYM\r\nQUIT\r\n]);

    return $self;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::tor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
