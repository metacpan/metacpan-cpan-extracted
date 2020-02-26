package Pcore::API::Proxy::Luminati;

use Pcore -class;
use Pcore::Util::UUID qw[uuid_v1mc_hex];
use AnyEvent::DNS;

has host     => 'zproxy.lum-superproxy.io';
has port     => 22225;
has username => ( required => 1 );
has password => ( required => 1 );
has zone     => ( required => 1 );

has country => ();

has _session_host => ( init_arg => undef );

sub get_proxy ( $self, $country = undef ) {
    $country //= $self->{country};

    my $proxy = "lum-customer-$self->{username}-zone-$self->{zone}";

    $proxy .= "-country-$country" if $country;

    $proxy .= ":$self->{password}\@$self->{host}:$self->{port}";

    return $proxy;
}

sub get_proxy_session ( $self, $country = undef ) {
    $country //= $self->{country};

    my $proxy = "lum-customer-$self->{username}-zone-$self->{zone}";

    $proxy .= "-country-$country" if $country;

    $proxy .= '-session-' . uuid_v1mc_hex;

    my $host = $self->_get_session_host;

    $proxy .= ":$self->{password}\@$host:$self->{port}";

    return $proxy;
}

sub restore_proxy_session ( $self, $host, $session ) {
    my $proxy = "connect://lum-customer-$self->{username}-zone-$self->{zone}";

    # $proxy .= "-country-$country" if $country;

    $proxy .= "-session-$session";

    $proxy .= ":$self->{password}\@$host:$self->{port}";

    return $proxy;
}

sub _get_session_host ($self) {
    if ( !$self->{_session_host} ) {
        AnyEvent::DNS::a $self->{host}, my $cv = P->cv;

        my @ip = $cv->recv;

        $self->{_session_host} = $ip[0] || $self->{host};
    }

    return $self->{_session_host};
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 8                    | ValuesAndExpressions::RequireNumberSeparators - Long number not separated with underscores                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Proxy::Luminati

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
