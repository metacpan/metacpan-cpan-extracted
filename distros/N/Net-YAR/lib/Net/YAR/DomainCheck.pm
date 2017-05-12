package Net::YAR::DomainCheck;

=head1 NAME

Net::YAR::DomainCheck - Emergency fail over domain.check implementations in case the Registrar or Registry is having troubles.

=cut

use strict;
use Net::YAR;

our $VERSION = $Net::YAR::VERSION;
our $YAR_TIMEOUT   = 5;  # Seconds
our $WHOIS_TIMEOUT = 29; # Seconds
our $WHOIS_PORT    = 43; # nicname
our $WHOIS_MAP     = {
    # tld => { whois => "whois.nic.tld", avail => UnregisteredDomainRegExp },
    com => {
        whois => "whois.crsnic.net",
        avail => qr/^No match for /m,
    },
    net => $WHOIS_MAP->{'com'},
    org => {
        whois => "whois.publicinterestregistry.net",
        avail => qr/^NOT FOUND/m,
    },
    info => {
        whois => "whois.afilias.info",
        avail => qr/^NOT FOUND/m,
    },
    biz => {
        whois => "whois.neulevel.biz",
        avail => qr/^Not found: /m,
    },
    us => {
        whois => "whois.nic.us",
        avail => qr/^Not found: /m,
    },
    uk => {
        whois => "whois.nic.uk",
        avail => qr/^\s*No match for/m,
    },
    co => {
        whois => "whois.nic.co",
        avail => qr/^Not found: /m,
    },
};

sub domain_check_whois {
    my $yar = shift;
    my $fail_resp = shift;
    my $args = shift;
    my $ref = $args->{'domain'} || $args->{'domains'};

    my @domains = ref $ref ? @$ref : $ref;
    my @rows = ();
    require IO::Socket;
    foreach my $domain (@domains) {
        $domain = lc $domain;
        $domain =~ s/\.+$//;
        if ($domain =~ /\.(\w+)$/) {
            my $tld = $1;
            if (my $w = $WHOIS_MAP->{$tld}) {
                my $old_alarm = alarm($WHOIS_TIMEOUT + 1);
                local $SIG{ALRM} = sub { die "$w->{whois}: Timeout!" };
                my $ok = eval {
                    if (my $io = new IO::Socket::INET
                        PeerHost => "$w->{whois}.:$WHOIS_PORT",
                        Timeout => $WHOIS_TIMEOUT,
                    ) {
                        $io->print("$domain\n");
                        my $whois = join "","[$w->{whois}]\n",<$io>;
                        $io->close;
                        push @rows, {
                            domain => lc $domain,
                            available => ($whois =~ $w->{'avail'} ? 1 : 0),
                        };
                    }
                    else {
                        die "$w->{whois}: Unable to verify availability: $!";
                    }
                    1;
                };
                alarm($old_alarm);
                $ok or die "$domain: $@";
            }
            else {
                die "$domain: Unimplemented whois server for TLD: $tld";
            }
        }
        else {
            die "$domain: Unable to determine tld";
        }
    }

    my $obj_args = {
        type        => 'success',
        request     => $fail_resp->{'request'},
        response    => "whois failover",
        method      => "domain_check_whois",
        data        => {rows => \@rows},
    };

    ### return the appropriate object
    return Net::YAR::Response->new($obj_args);
}

sub lwp_args_yar_default {
    return [ timeout => $YAR_TIMEOUT ];
}

1;
