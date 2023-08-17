
# purpose: test Mnet::IP functions

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 225;

# loop through test data in format '$function $input => $output'
foreach my $line (<DATA>) {
    $line =~ s/#.*//;
    next if $line !~ /\S/;
    die "test DATA error, $line" if $line !~ /^(\S+)\s+(\S+)\s+=>\s+(.*)\s*$/;
    my ($function, $input, $output) = ($1, $2, $3);
    Mnet::T::test_perl({
        name    => "$function $input => $output",
        perl    => <<'        perl-eof',
            use warnings;
            use strict;
            use Mnet::IP;
            my ($function, $input) = (shift, shift);
            $input = undef if $input eq "undef";
            my @output = &{\&{"Mnet::IP::$function"}}($input);
            my @clean = (); push @clean, $_ // "undef" foreach @output;
            print join(",", @clean);
        perl-eof
        args    => "$function $input",
        expect  => $output,
    });
}

# finished
exit;

__DATA__

# test parse function with ipv4-sized /cidr
parse /0 => undef,undef,0,0.0.0.0
parse /1 => undef,undef,1,128.0.0.0
parse /7 => undef,undef,7,254.0.0.0
parse /8 => undef,undef,8,255.0.0.0
parse /9 => undef,undef,9,255.128.0.0
parse /15 => undef,undef,15,255.254.0.0
parse /16 => undef,undef,16,255.255.0.0
parse /17 => undef,undef,17,255.255.128.0
parse /23 => undef,undef,23,255.255.254.0
parse /24 => undef,undef,24,255.255.255.0
parse /25 => undef,undef,25,255.255.255.128
parse /26 => undef,undef,26,255.255.255.192
parse /27 => undef,undef,27,255.255.255.224
parse /28 => undef,undef,28,255.255.255.240
parse /29 => undef,undef,29,255.255.255.248
parse /30 => undef,undef,30,255.255.255.252
parse /31 => undef,undef,31,255.255.255.254
parse /32 => undef,undef,32,255.255.255.255

# test parse function with ipv6-sized /cidr
parse /33  => undef,undef,33,undef
parse /127 => undef,undef,127,undef
parse /128 => undef,undef,128,undef

# test parse function with invalid /cidr
parse /129 => undef,undef,undef,undef
parse /xxx => undef,undef,undef,undef
parse /32x => undef,undef,undef,undef

# test parse function with /mask
parse /0.0.0.0 => undef,undef,0,0.0.0.0
parse /128.0.0.0 => undef,undef,1,128.0.0.0
parse /254.0.0.0 => undef,undef,7,254.0.0.0
parse /255.0.0.0 => undef,undef,8,255.0.0.0
parse /255.128.0.0 => undef,undef,9,255.128.0.0
parse /255.254.0.0 => undef,undef,15,255.254.0.0
parse /255.255.0.0 => undef,undef,16,255.255.0.0
parse /255.255.128.0 => undef,undef,17,255.255.128.0
parse /255.255.254.0 => undef,undef,23,255.255.254.0
parse /255.255.255.0 => undef,undef,24,255.255.255.0
parse /255.255.255.128 => undef,undef,25,255.255.255.128
parse /255.255.255.192 => undef,undef,26,255.255.255.192
parse /255.255.255.224 => undef,undef,27,255.255.255.224
parse /255.255.255.240 => undef,undef,28,255.255.255.240
parse /255.255.255.248 => undef,undef,29,255.255.255.248
parse /255.255.255.252 => undef,undef,30,255.255.255.252
parse /255.255.255.254 => undef,undef,31,255.255.255.254
parse /255.255.255.255 => undef,undef,32,255.255.255.255

# test parse function with invalid /mask
parse /256.0.0.0 => undef,undef,undef,undef
parse /0.256.0.0 => undef,undef,undef,undef
parse /0.0.256.0 => undef,undef,undef,undef
parse /0.0.0.256 => undef,undef,undef,undef
parse /0.0.0.0.x => undef,undef,undef,undef
parse /0.0.0.x => undef,undef,undef,undef
parse /132.0.0.0 => undef,undef,undef,undef

# test parse function with ipv4
parse 0.0.0.0 => 0.0.0.0,undef,undef,undef
parse 127.0.0.1 => 127.0.0.1,undef,undef,undef
parse 255.255.255.255 => 255.255.255.255,undef,undef,undef
parse 256.0.0.0 => undef,undef,undef,undef
parse 0.256.0.0 => undef,undef,undef,undef
parse 0.0.256.0 => undef,undef,undef,undef
parse 0.0.0.256 => undef,undef,undef,undef
parse 0.0.0 => undef,undef,undef,undef
parse 0.0 => undef,undef,undef,undef
parse 0 => undef,undef,undef,undef

# test parse function with ipv4/cidr
parse 0.0.0.0/0 => 0.0.0.0,undef,0,0.0.0.0
parse 10.0.0.0/8 => 10.0.0.0,undef,8,255.0.0.0
parse 127.0.0.1/32 => 127.0.0.1,undef,32,255.255.255.255
parse 127.0.0.1/33 => undef,undef,undef,undef
parse 127.0.0.1/x => undef,undef,undef,undef
parse 0/0 => undef,undef,undef,undef

# test parse function with ipv4/mask
parse 0.0.0.0/0.0.0.0 => 0.0.0.0,undef,0,0.0.0.0
parse 10.0.0.0/255.0.0.0 => 10.0.0.0,undef,8,255.0.0.0
parse 127.0.0.1/255.255.255.255 => 127.0.0.1,undef,32,255.255.255.255
parse 127.0.0.1/255.255.255.256 => undef,undef,undef,undef
parse 127.0.0.1/x.x.x.x => undef,undef,undef,undef
parse 0/0.0.0.0 => undef,undef,undef,undef

# test parse function with ipv6
parse ::1 => undef,::1,undef,undef
parse ffff::1 => undef,ffff::1,undef,undef
parse 1:2:3:4:5:6:7:8 => undef,1:2:3:4:5:6:7:8,undef,undef
parse 1:2:3:4:5:6:7 => undef,undef,undef,undef
parse :::1 => undef,undef,undef,undef
parse 1::2::3 => undef,undef,undef,undef
parse 1:2:3:4:5:6:7:8:9 => undef,undef,undef,undef
parse ::12345 => undef,undef,undef,undef
parse ::x => undef,undef,undef,undef

# test parse function with ipv6 and embedded ip4v dotted decimal text
parse ::127.0.0.1 => undef,::127.0.0.1,undef,undef
parse ::127.0.0.1/96 => undef,::127.0.0.1,96,undef
parse ::127.0.0.1/0 => undef,undef,undef,undef
parse ::127.0.0.1/128 => undef,undef,undef,undef
parse ::256.0.0.0 => undef,undef,undef,undef
parse ::0.256.0.0 => undef,undef,undef,undef
parse ::0.0.256.0 => undef,undef,undef,undef
parse ::0.0.0.256 => undef,undef,undef,undef

# test parse function with ipv6/cidr
parse ::1/0 => undef,::1,0,undef
parse ::1/128 => undef,::1,128,undef
parse ::1/129 => undef,undef,undef,undef
parse ::1/x => undef,undef,undef,undef

# test parse function with invalid input
parse x/x => undef,undef,undef,undef
parse x => undef,undef,undef,undef
parse / => undef,undef,undef,undef
parse undef => undef,undef,undef,undef

# test binary function with ipv4
binary 0.0.0.0 => 00000000000000000000000000000000
binary 1.0.0.0 => 00000001000000000000000000000000
binary 0.1.0.0 => 00000000000000010000000000000000
binary 0.0.1.0 => 00000000000000000000000100000000
binary 0.0.0.1 => 00000000000000000000000000000001
binary 255.0.0.0 => 11111111000000000000000000000000
binary 0.0.0.255 => 00000000000000000000000011111111
binary 127.0.0.1/32 => 01111111000000000000000000000001
binary 127.0.0.1/255.255.255.255 => 01111111000000000000000000000001

# test binary function with ipv6
binary :: => 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
binary ::1 => 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
binary ::1/128 => 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
binary ::1.1.1.1 => 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000010000000100000001
binary 1111::ffff => 00010001000100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111

# test binary function with invalid inputs
binary / => undef
binary /32 => undef
binary /128 => undef
binary /255.255.255.255 => undef
binary ::1/129 => undef
binary undef => undef

# test cidr function
cidr / => undef
cidr /0 => 0
cidr /32 => 32
cidr /128 => 128
cidr /0.0.0.0 => 0
cidr 0.0.0.0/0 => 0
cidr 0.0.0.0/0.0.0.0 => 0
cidr /255.255.255.255 => 32
cidr 255.255.255.255/32 => 32
cidr ::0/128 => 128
cidr ::0/0 => 0
cidr undef => undef

# test ip function
ip 127.0.0.1 => 127.0.0.1
ip 127.0.0.1/32 => 127.0.0.1
ip 127.0.0.1/255.255.255.255 => 127.0.0.1
ip ::1 => ::1
ip ::1/128 => ::1
ip ::127.0.0.1 => ::127.0.0.1
ip ::127.0.0.1/96 => ::127.0.0.1
ip ::127.0.0.1/255.255.255.255 => undef
ip x => undef
ip undef => undef

# test ipv4 function
ipv4 127.0.0.1 => 127.0.0.1
ipv4 127.0.0.1/32 => 127.0.0.1
ipv4 127.0.0.1/255.255.255.255 => 127.0.0.1
ipv4 ::1 => undef
ipv4 ::127.0.0.1 => undef
ipv4 x => undef
ipv4 undef => undef

# test ipv6 function
ipv6 ::1 => ::1
ipv6 ::1/128 => ::1
ipv6 ::127.0.0.1 => ::127.0.0.1
ipv6 ::127.0.0.1/96 => ::127.0.0.1
ipv6 127.0.0.1 => undef
ipv6 127.0.0.1/32 => undef
ipv6 127.0.0.1/255.255.255.255 => undef
ipv6 x => undef
ipv6 undef => undef

# test mask function
mask / => undef
mask /0 => 0.0.0.0
mask /32 => 255.255.255.255
mask /128 => undef
mask /0.0.0.0 => 0.0.0.0
mask 0.0.0.0/0 => 0.0.0.0
mask 0.0.0.0/0.0.0.0 => 0.0.0.0
mask /255.255.255.255 => 255.255.255.255
mask 255.255.255.255/32 => 255.255.255.255
mask ::0/128 => undef
mask ::0/0 => undef
mask undef => undef

# test network function with ipv4 inputs
network 127.0.0.1/32 => 127.0.0.1
network 10.10.10.8/30 => 10.10.10.8
network 10.10.10.9/30 => 10.10.10.8
network 10.10.10.10/30 => 10.10.10.8
network 10.10.10.11/30 => 10.10.10.8
network 172.16.0.1/12 => 172.16.0.0
network 172.31.255.255/12 => 172.16.0.0

# test network function with ipv6 inputs
network ::1/128 => ::1
network ::8/126 => ::8
network ::9/126 => ::8
network ::a/126 => ::8
network ::b/126 => ::8
network 1:2:3:4:5:6:7:8/64 => 1:2:3:4::
network 1:2:3:4:5:6:7:8/96 => 1:2:3:4:5:6::
network 1:2:0:0:0:0:7:8/128 => 1:2::7:8
network ::ffff/122 => ::ffc0

# test network function with invalid inputs
network 127.0.0.1 => undef
network 127.0.0.1/0 => undef
network ::1 => undef
network ::1/0 => undef
network x => undef
network undef => undef

# test wildcard function with /cidr
wildcard /0 => 255.255.255.255
wildcard /1 => 127.255.255.255
wildcard /7 => 1.255.255.255
wildcard /8 => 0.255.255.255
wildcard /9 => 0.127.255.255
wildcard /15 => 0.1.255.255
wildcard /16 => 0.0.255.255
wildcard /17 => 0.0.127.255
wildcard /23 => 0.0.1.255
wildcard /24 => 0.0.0.255
wildcard /31 => 0.0.0.1
wildcard /32 => 0.0.0.0
wildcard /33 => undef
wildcard /128 => undef

# test wildcard function with /mask
wildcard /0.0.0.0 => 255.255.255.255
wildcard /128.0.0.0 => 127.255.255.255
wildcard /254.0.0.0 => 1.255.255.255
wildcard /255.0.0.0 => 0.255.255.255
wildcard /255.128.0.0 => 0.127.255.255
wildcard /255.254.0.0 => 0.1.255.255
wildcard /255.255.0.0 => 0.0.255.255
wildcard /255.255.128.0 => 0.0.127.255
wildcard /255.255.254.0 => 0.0.1.255
wildcard /255.255.255.0 => 0.0.0.255
wildcard /255.255.255.128 => 0.0.0.127
wildcard /255.255.255.254 => 0.0.0.1
wildcard /255.255.255.255 => 0.0.0.0

# test wildcard with ipv4, ipv4/cidr and ipv4/mask
wildcard 127.0.0.1 => undef
wildcard 127.0.0.1/0 => 255.255.255.255
wildcard 127.0.0.1/255.255.255.255 => 0.0.0.0

# test wildcard with ipv6 and ipv6/cidr
wildcard ::1 => undef
wildcard ::1/0 => undef
wildcard ::1/128 => undef

# test wildcard function with invalid input
wildcard / => undef
wildcard /x.x.x.x => undef
wildcard /x => undef
wildcard undef => undef

