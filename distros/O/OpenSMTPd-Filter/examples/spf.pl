#!/usr/bin/perl
use v5.16;
use warnings;

use OpenSMTPd::Filter;

use OpenBSD::Unveil;
use OpenBSD::Pledge;
use Mail::SPF;

# Preload modules for pledge(2)
use Net::DNS;
require Mail::SPF::v1::Record;
require Mail::SPF::v2::Record;

# This lets us see if there are other modules we may need to preload
unshift @INC, sub { warn "Attempted to load $_[1]"; return };

# Something tries to load /etc/hosts and possibly other things
# but it works fine if unveil says they don't exist.
unveil();
pledge(qw< dns inet rpath >) || die "Unable to pledge: $!";

my $debug      = 1;
my $spf_server = Mail::SPF::Server->new(
    resolver => Net::DNS::Resolver->new(
        nameservers => ['127.0.0.1'],
        debug       => $debug,
    ),
);

OpenSMTPd::Filter->new(
    debug => $debug,
    on    => {
        filter => {
            'smtp-in' => {
                'mail-from' => \&verify_spf,
                'data-line' => \&add_spf_header,
            }
        }
    }
)->ready;

sub verify_spf {
    my ( $phase, $s ) = @_;

    my %params = (
        versions   => [ 1, 2 ],
        scope      => 'helo',
        ip_address => $s->{state}->{src} =~ s/:\d+$//r, # remove port
        identity   => $s->{state}->{identity},
    );

    if ( my $address = $s->{events}->[-1]->{address} ) {
        $params{scope}         = 'mfrom';
        $params{helo_identity} = $params{identity};
        $params{identity}      = $address;
    }

    my $result = $spf_server->process(
        Mail::SPF::Request->new( %params ) );

    $s->{spf_header} = $result->received_spf_header;
    STDERR->say( $s->{spf_header} );

    return reject => '451 Temporary failure, please try again later.'
        if $result->is_code("softfail");

    return disconnect => '550 SPF check failed.'
        if $result->is_code("fail");

    # We ignore other errors and let the mail through
    return 'proceed';
}

sub add_spf_header {
    my ( $phase, $s, @lines ) = @_;

    if (    $lines[0] eq ''
        and $s->{spf_header}
        and not $s->{state}->{message}->{spf_header} )
    {
        unshift @lines, $s->{spf_header};
        $s->{state}->{message}->{spf_header} = $s->{spf_header};
    }

    return @lines;
}
