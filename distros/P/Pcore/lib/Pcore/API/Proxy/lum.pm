package Pcore::API::Proxy::lum;

use Pcore -const, -class;
use Pcore::Util::UUID qw[uuid_v1mc_hex];
use AnyEvent::DNS;

with qw[Pcore::API::Proxy];

has is_http => 1;

has _params => ();

const our $DEFAULT_HOST => 'zproxy.lum-superproxy.io';
const our $DEFAULT_PORT => 22225;

around new => sub ( $orig, $self, $uri ) {
    $self = $self->$orig;

    $self->{uri} = $uri;

    return $self;
};

# https://luminati.io/faq#examples
# session
# country
# state
# city
# dns:
#     local - domain names will be resolved and cached by the Super Proxy
#     remote - DNS resolution at the Proxy Peer
# direct -  perform the request from the super proxy directly instead of the IP of the peer
# zone
sub new_ip ( $self, %args ) {
    my $params = $self->{params} //= do {
        my $data;

        my $username = $self->{uri}->{username};

        while ( $username =~ /(lum-customer|zone|dns|country|state|city|session)-([^-]+)/smg ) {
            $data->{$1} = $2;
        }

        $data;
    };

    my %params = ( $params->%*, %args );

    my $host = $self->{uri}->{host};

    # session
    if ( $params{session} ) {
        $params{session} = uuid_v1mc_hex;

        $host = $self->_get_session_host( $params{country} ) if $host eq $DEFAULT_HOST;
    }

    my $password = delete $params{password} || $self->{uri}->{password};

    my $uri = 'lum://' . join( '-', map { $params{$_} ? "$_-$params{$_}" : () } sort keys %params ) . ":$password\@$host:$self->{uri}->{port}";

    $uri = P->uri($uri);

    return $self->new($uri);
}

sub _get_session_host ( $self, $country = undef ) {
    my $cv = P->cv;

    if ($country) {
        AnyEvent::DNS::a "servercountry-$country.$DEFAULT_HOST", $cv;
    }
    else {
        AnyEvent::DNS::a $DEFAULT_HOST, $cv;
    }

    my @ip = $cv->recv;

    return $ip[0];
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 14                   | ValuesAndExpressions::RequireNumberSeparators - Long number not separated with underscores                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::lum

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
