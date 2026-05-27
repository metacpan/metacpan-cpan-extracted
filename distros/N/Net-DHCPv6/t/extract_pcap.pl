#!perl
use strictures 2;
use lib 'lib';
use Net::DHCPv6;

my $in = do { local $/; <> }
    or die "No input";

my @packets;
my $current;
for my $line ( split /\n/, $in ) {
    if ( $line =~ m/dhcp6 (solicit|advertise|request|reply|release)/ ) {
        push @packets, $current if $current;
        $current = {
            type     => $1,
            type_num => {
                solicit   => 1,
                advertise => 2,
                request   => 3,
                reply     => 7,
                release   => 8
            }->{$1},
            hex => ''
        };
    }
    elsif ( $current && $line =~ m/^\s+0x[0-9a-f]+:\s+(.*?)\s*$/ ) {
        my $line_hex = $1;
        $line_hex =~ s/\s+//g;
        $current->{hex} .= $line_hex;
    }
}
push @packets, $current if $current;

my $count = 0;
for my $pkt ( @packets ) {

    # Find DHCPv6 payload within hex: skip eth(14) + ip6(40) + udp(8) = 62 bytes = 124 hex chars
    my $dhcp_hex   = substr( $pkt->{hex}, 124 );
    my $dhcp_bytes = pack( 'H*', $dhcp_hex );
    my ( $decoded, $error ) = Net::DHCPv6->decode_with_error( $dhcp_bytes );
    ++$count;
    if ( $decoded ) {
        my $tid = $decoded->transaction_id;
        printf "%2d. %-10s tid=0x%06X\n", $count, uc( $pkt->{type} ), $tid;
        my $opts = $decoded->options;
        for my $opt ( @$opts ) {
            my $name = $opt->type // 'UNKNOWN';
            printf "      Option %-3d %-20s\n", $opt->code, $name;
            if ( $opt->code == 6 && $opt->can( 'requested_options' ) ) {
                printf "        codes: %s\n", join( ', ', @{ $opt->requested_options } );
            }
            if ( $opt->code == 25 && $opt->can( 'iaid' ) ) {
                printf "        IAPD iaid=%d t1=%d t2=%d\n", $opt->iaid, $opt->t1, $opt->t2;
            }
            if ( $opt->code == 26 && $opt->can( 'prefix_length' ) ) {
                printf "        prefix=%d addr=%s\n", $opt->prefix_length, unpack( 'H*', $opt->address );
            }
            if ( $opt->code == 13 && $opt->can( 'status_code' ) ) {
                printf "        status=%d msg=%s\n", $opt->status_code, $opt->message;
            }
        }
    }
    else {
        printf "%2d. %-10s ERROR: %s\n", $count, uc( $pkt->{type} ), $error // 'decode failed';
    }
}
