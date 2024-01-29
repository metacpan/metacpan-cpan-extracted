package Socket::More::IPRanges;
use Net::IP::Lite qw<ip2bin>;

use Export::These qw<ipv4_group ipv6_group ip2bin ip_iptypev4 ip_iptypev6>;

##DIRECT COPY FROM Net::IP
##########################
my $ERROR;
my $ERRNO;
# Definition of the Ranges for IPv4 IPs
my %IPv4ranges = (
    '00000000'                         => 'PRIVATE',     # 0/8
    '00001010'                         => 'PRIVATE',     # 10/8
    '0110010001'                       => 'SHARED',      # 100.64/10
    '01111111'                         => 'LOOPBACK',    # 127.0/8
    '1010100111111110'                 => 'LINK-LOCAL',  # 169.254/16
    '101011000001'                     => 'PRIVATE',     # 172.16/12
    '110000000000000000000000'         => 'RESERVED',    # 192.0.0/24
    '110000000000000000000010'         => 'TEST-NET',    # 192.0.2/24
    '110000000101100001100011'         => '6TO4-RELAY',  # 192.88.99.0/24 
    '1100000010101000'                 => 'PRIVATE',     # 192.168/16
    '110001100001001'                  => 'RESERVED',    # 198.18/15
    '110001100011001101100100'         => 'TEST-NET',    # 198.51.100/24
    '110010110000000001110001'         => 'TEST-NET',    # 203.0.113/24
    '1110'                             => 'MULTICAST',   # 224/4
    '1111'                             => 'RESERVED',    # 240/4
    '11111111111111111111111111111111' => 'BROADCAST',   # 255.255.255.255/32
);
 
# Definition of the Ranges for Ipv6 IPs
my %IPv6ranges = (
    '00000000'                                      => 'RESERVED',                  # ::/8
    ('0' x 128)                                     => 'UNSPECIFIED',               # ::/128
    ('0' x 127) . '1'                               => 'LOOPBACK',                  # ::1/128
    ('0' x  80) . ('1' x 16)                        => 'IPV4MAP',                   # ::FFFF:0:0/96
    '00000001'                                      => 'RESERVED',                  # 0100::/8
    '0000000100000000' . ('0' x 48)                 => 'DISCARD',                   # 0100::/64
    '0000001'                                       => 'RESERVED',                  # 0200::/7
    '000001'                                        => 'RESERVED',                  # 0400::/6
    '00001'                                         => 'RESERVED',                  # 0800::/5
    '0001'                                          => 'RESERVED',                  # 1000::/4
    '001'                                           => 'GLOBAL-UNICAST',            # 2000::/3
    '0010000000000001' . ('0' x 16)                 => 'TEREDO',                    # 2001::/32
    '00100000000000010000000000000010' . ('0' x 16) => 'BMWG',                      # 2001:0002::/48            
    '00100000000000010000110110111000'              => 'DOCUMENTATION',             # 2001:DB8::/32
    '0010000000000001000000000001'                  => 'ORCHID',                    # 2001:10::/28
    '0010000000000010'                              => '6TO4',                      # 2002::/16
    '010'                                           => 'RESERVED',                  # 4000::/3
    '011'                                           => 'RESERVED',                  # 6000::/3
    '100'                                           => 'RESERVED',                  # 8000::/3
    '101'                                           => 'RESERVED',                  # A000::/3
    '110'                                           => 'RESERVED',                  # C000::/3
    '1110'                                          => 'RESERVED',                  # E000::/4
    '11110'                                         => 'RESERVED',                  # F000::/5
    '111110'                                        => 'RESERVED',                  # F800::/6
    '1111110'                                       => 'UNIQUE-LOCAL-UNICAST',      # FC00::/7
    '111111100'                                     => 'RESERVED',                  # FE00::/9
    '1111111010'                                    => 'LINK-LOCAL-UNICAST',        # FE80::/10
    '1111111011'                                    => 'RESERVED',                  # FEC0::/10
    '11111111'                                      => 'MULTICAST',                 # FF00::/8
);

#------------------------------------------------------------------------------
# Subroutine ip_iptypev4
# Purpose           : Return the type of an IP (Public, Private, Reserved)
# Params            : IP to test, IP version
# Returns           : type or undef (invalid)
sub ip_iptypev4 {
    my ($ip) = @_;
    no warnings "uninitialized";
 
    # check ip
    if ($ip !~ m/^[01]{1,32}$/) {
        $ERROR = "$ip is not a binary IPv4 address $ip";
        $ERRNO = 180;
        return;
    }
     
    # see if IP is listed
    foreach (sort { length($b) <=> length($a) } keys %IPv4ranges) {
        return ($IPv4ranges{$_}) if ($ip =~ m/^$_/);
    }
 
    # not listed means IP is public
    return 'PUBLIC';
}
 
#------------------------------------------------------------------------------
# Subroutine ip_iptypev6
# Purpose           : Return the type of an IP (Public, Private, Reserved)
# Params            : IP to test, IP version
# Returns           : type or undef (invalid)
sub ip_iptypev6 {
    my ($ip) = @_;
    no warnings "uninitialized";

    # check ip
    if ($ip !~ m/^[01]{1,128}$/) {
        $ERROR = "$ip is not a binary IPv6 address";
        $ERRNO = 180;
        return;
    }
     
    foreach (sort { length($b) <=> length($a) } keys %IPv6ranges) {
        return ($IPv6ranges{$_}) if ($ip =~ m/^$_/);
    }
 
    # How did we get here? All IPv6 addresses should match 
    $ERROR = "Cannot determine type for $ip";
    $ERRNO = 180;
    return;
}

#######
#END COPY FROM Net::IP
sub ipv6_group {
        ip_iptypev6 &ip2bin
}
sub ipv4_group {
        ip_iptypev4 &ip2bin
}
1;
