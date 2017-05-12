# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DHCPv6-DUID-Parser.t'

#########################

use Test::More tests => 46;
use strict;

BEGIN { use_ok('Net::DHCPv6::DUID::Parser') };

#########################

my $p = new Net::DHCPv6::DUID::Parser;

# Check different decoder types
isa_ok ($p, 'Net::DHCPv6::DUID::Parser', 'is a Net::DHCPv6::DUID::Parser object');
$p = undef;
is     ($p, undef, 'object is not defined');
$p = new Net::DHCPv6::DUID::Parser(decode => 'bin', warnings => 1);
isa_ok ($p, 'Net::DHCPv6::DUID::Parser', 'is a Net::DHCPv6::DUID::Parser object');
$p = undef;
is     ($p, undef, 'object is not defined');
$p = new Net::DHCPv6::DUID::Parser(decode => 'hex', warnings => 0);
isa_ok ($p, 'Net::DHCPv6::DUID::Parser', 'is a Net::DHCPv6::DUID::Parser object');

# Check all the methods we want are here
can_ok ($p, qw/decode type identifier enterprise_number iana_hw_type time local_link_address/);

# Test type 1: DUID-LLT
is     ($p->decode('000100011286F55C0007E90F2FEE'), 1, 'decode 000100011286F55C0007E90F2FEE successful');
cmp_ok ($p->type, '==', 1, 'DUID type is 1');
is     ($p->type(format => 'text'), 'DUID-LLT', 'DUID type is DUID-LLT');
is     ($p->local_link_address, '0007e90f2fee', 'local link address decoded ok');
is     ($p->local_link_address(format => 'ethernet_mac'), '00-07-e9-0f-2f-ee', 'local link address with formatting ok');
cmp_ok ($p->iana_hw_type, '==', '1', 'IANA hardware type is 1');
is     ($p->iana_hw_type(format => 'text'), 'Ethernet (10Mb)', 'IANA hardware type is Ethernet (10Mb)');
cmp_ok ($p->time, '==', 310834524, 'time is 310834524 seconds since Midnight, 1 January 2000');
is     ($p->enterprise_number, undef, 'Enterprise number is not defined');
is     ($p->identifier, undef, 'Identifier is not defined');

# Test type 2: DUID-EN
is     ($p->decode('0002000000090CC084D303000912'), 1, 'decode 0002000000090CC084D303000912 successful');
cmp_ok ($p->type, '==', 2, 'DUID type is 2');
is     ($p->type(format => 'text'), 'DUID-EN', 'DUID type is DUID-EN');
is     ($p->local_link_address, undef, 'local link address is not defined');
is     ($p->local_link_address(format => 'ethernet_mac'), undef, 'local link address is not defined');
is     ($p->iana_hw_type, undef, 'IANA hardware type is not defined');
is     ($p->iana_hw_type(format => 'text'), undef, 'IANA hardware type is not defined');
is     ($p->time, undef, 'time is not defined');
is     ($p->enterprise_number, 9, 'Enterprise number is 9');
is     ($p->identifier, '0cc084d303000912', 'Identifier is 0cc084d303000912');

# Test type 3: DUID-LL
is     ($p->decode('000300010004ED9F7522'), 1, 'decode 000300010004ED9F7522 successful');
cmp_ok ($p->type, '==', 3, 'DUID type is 3');
is     ($p->type(format => 'text'), 'DUID-LL', 'DUID type is DUID-LL');
is     ($p->local_link_address, '0004ed9f7522', 'local link address decoded ok');
is     ($p->local_link_address(format => 'ethernet_mac'), '00-04-ed-9f-75-22', 'local link address with formatting ok');
cmp_ok ($p->iana_hw_type, '==', '1', 'IANA hardware type is 1');
is     ($p->iana_hw_type(format => 'text'), 'Ethernet (10Mb)', 'IANA hardware type is Ethernet (10Mb)');
is     ($p->time, undef, 'time is not defined');
is     ($p->enterprise_number, undef, 'Enterprise number is not defined');
is     ($p->identifier, undef, 'Identifier is not defined');

# Test rubbish
is     ($p->decode('foo'), undef, 'decode foo unsuccessful');
is     ($p->type, undef, 'DUID type is undef');
is     ($p->local_link_address, undef, 'local link address is not defined');
is     ($p->local_link_address(format => 'ethernet_mac'), undef, 'local link address is not defined');
is     ($p->iana_hw_type, undef, 'IANA hardware type is not defined');
is     ($p->iana_hw_type(format => 'text'), undef, 'IANA hardware type is not defined');
is     ($p->time, undef, 'time is not defined');
is     ($p->enterprise_number, undef, 'Enterprise number is not defined');
is     ($p->identifier, undef, 'Identifier is not defined');


