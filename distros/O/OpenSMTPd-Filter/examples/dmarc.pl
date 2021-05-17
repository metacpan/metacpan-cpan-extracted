#!/usr/bin/perl
use v5.16;
use warnings;

# WARNING: This example "works" but has serious limitations
# Make sure you understand DMARC and modify this as appropriate.
# If you do understand it, patches welcome!

use OpenSMTPd::Filter;

use OpenBSD::Unveil;
use OpenBSD::Pledge;
use Mail::SPF;
use Mail::DKIM::Verifier;
use Mail::DMARC::PurePerl;

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

my $filter = OpenSMTPd::Filter->new(
    debug => $debug,
    on    => { filter => { 'smtp-in' => {
        'helo'      => \&verify_spf,
        'ehlo'      => \&verify_spf,
        'mail-from' => \&verify_spf,
        'data-line' => sub {
            dkim_verifier(@_);
            add_spf_header(@_);
        },
        'commit' => \&dmarc_result,
    } } }
);

$filter->ready;

sub verify_spf {
    my ( $phase, $s ) = @_;

    my %params = (
        versions   => [ 1, 2 ],
        scope      => 'helo',
        ip_address => $s->{state}->{src} =~ s/:\d+$//r,    # remove port
        identity => $s->{state}->{identity} || $s->{events}->[-1]->{identity},
    );

    if ( my $address = $s->{events}->[-1]->{address} ) {
        $params{scope}         = 'mfrom';
        $params{helo_identity} = $params{identity};
        $params{identity}      = $address;
    }

    my $result = $spf_server->process( Mail::SPF::Request->new(%params) );

    $s->{state}->{message}->{spf_result}{ $params{scope} } = $result;

    # TODO: A server sending multiple messages, with a From: <> message
    # TODO: after a good message could get the wrong SPF header.
    $s->{spf_header} = $result->received_spf_header;
    STDERR->say( $s->{spf_header} );

    # We handle errors based on DMARC policy and ignore them here.
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

sub dkim_verifier {
    my ( $phase, $s, $line ) = @_;

    my $dkim = $s->{state}->{message}->{dkim_verifier}
        ||= Mail::DKIM::Verifier->new();

    if ( $line eq '.' ) {
        $dkim->CLOSE();
    }
    elsif ( $line =~ /^\.(.+)$/ ) {
        $dkim->PRINT("$1\015\012");
    }
    else {
        $dkim->PRINT("$line\015\012");
    }

    return $line;
}

sub dmarc_result {
    my ( $phase, $s ) = @_;

    my $state   = $s->{state};
    my $message = $state->{message};
    my $dkim    = $message->{dkim_verifier};

    my $dkim_result = $dkim->result();

    my @spf_results = map {
        my $scope  = $_;
        my $result = $message->{spf_result}->{$_};
        my $domain = $result->request->identity;
        $domain =~ s/^.*@//;

        {   scope  => $scope,
            domain => $domain,
            result => $result->result_code,
        }
    } keys %{ $message->{spf_result} || {} };

    my $dmarc = Mail::DMARC::PurePerl->new(
        envelope_from => $filter->{_config}->{admd},
        dkim          => $dkim,
        spf           => \@spf_results,
    );

    if ( my $source_ip = $state->{src} ) {
        $source_ip =~ s/:\d+$//;           # remove port
        $source_ip =~ s/^\[(.*)\]$/$1/;    # remove v6 brackets
        $dmarc->source_ip($source_ip);
    }

    if ( my $from = $message->{'mail-from'} ) {
        $dmarc->envelope_from($1) if $from =~ /@(.*)$/;
    }

    if ( my $to = $message->{'rcpt-to'}->[0] ) {
        $dmarc->envelope_to($1) if $to =~ /@(.*)$/;
    }

    if ( my $from = $dkim->message_originator->host ) {
        $dmarc->header_from($from);
    }

    my $result = $dmarc->validate;

    return 'proceed' if $result->result eq 'pass';

    # any result that did not pass is a fail. Now for disposition

    if ( $result->disposition eq 'reject' ) {
        warn "Rejecting due to DMARC\n" if $debug;
        return disconnect => '550 DMARC check failed.';
    }

    if ( $result->disposition eq 'quarantine' ) {
        warn "Quarantining due to DMARC\n" if $debug;
        return 'junk';
    }

    # If the DMARC policy disposition is 'none',
    # we ignore other errors and let the mail through
    warn "Ignoring DMARC failure as requested\n" if $debug;
    return 'proceed';
}
