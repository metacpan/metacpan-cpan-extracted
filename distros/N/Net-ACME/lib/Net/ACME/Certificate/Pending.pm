package Net::ACME::Certificate::Pending;

=encoding utf-8

=head1 NAME

Net::ACME::Certificate::Pending - for when the cert isn’t ready yet

=head1 SYNOPSIS

    my $need_retry = Net::ACME::Certificate::Pending->new(
        uri => 'http://path/to/cert',
        retry_after => 30,  #i.e., retry after 30 seconds
    );

    my $cert;

    while (!$cert) {
        if ($need_retry->is_time_to_poll()) {
            $cert = $need_retry->poll();
        }

        sleep 1;
    }

=cut

use strict;
use warnings;

use parent qw( Net::ACME::RetryAfter );

use Net::ACME::Certificate ();

sub _handle_non_202_poll {
    my ( $self, $resp ) = @_;

    $resp->die_because_unexpected() if $resp->status() != 201;

    return Net::ACME::Certificate->new(
        content         => $resp->content(),
        type            => $resp->header('content-type'),
        issuer_cert_uri => { $resp->links() }->{'up'},
    );
}

1;
