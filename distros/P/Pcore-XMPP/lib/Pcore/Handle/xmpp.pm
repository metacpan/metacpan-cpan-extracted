package Pcore::Handle::xmpp;

use Pcore -class;
use Net::XMPP;

with qw[Pcore::Handle::Wrapper];

sub _connect ($self) {
    my $uri = $self->uri;

    my $h = Net::XMPP::Client->new;

    my $host = exists $uri->query_params->{gtalk} || $uri->host->name eq 'gmail.com' ? 'talk.google.com' : $uri->host->name;

    my $status = $h->Connect(
        hostname       => $host,
        port           => $uri->port || 5222,
        componentname  => $uri->host->name,
        connectiontype => 'tcpip',
        tls            => 1,
        ssl_ca_path    => P->ca->ca_file,
    );

    die 'XMPP connection error' unless $h->Connected;

    my $resource = $uri->username . q[@] . $uri->host->name . ' <' . $uri->username . q[@] . $uri->host->name . q[>];

    my @auth_res = $h->AuthSend(
        username => $uri->username,
        password => $uri->password,
        resource => $resource,
    );

    die 'XMPP authentication error' if !@auth_res || $auth_res[0] ne 'ok';

    return $h;
}

sub _disconnect ($self) {
    $self->h->Disconnect;

    return;
}

sub sendmsg ( $self, $to, $msg ) {
    $self->h->MessageSend( to => $to, body => $msg );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 8                    | * Private subroutine/method '_connect' declared but not used                                                   |
## |      | 39                   | * Private subroutine/method '_disconnect' declared but not used                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::xmpp

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
