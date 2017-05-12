# -*- mode: cperl; cperl-indent-level: 4; -*-
# vi:ai:sm:et:sw=4:ts=4

# $Id: POE-Filter-Log-IPTables.t,v 1.7 2005/11/18 23:46:43 paulv Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Filter-Log-IPTables.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More qw(no_plan);
use Test::More tests => 129;
BEGIN { use_ok('IPTables') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $test_data = [
                 # TCP
                 # 0 - base
                 "Jan 11 17:43:26 malloc kernel: IN=eth2 OUT= MAC= SRC=192.168.50.113 DST=10.30.245.53 LEN=60 TOS=0x00 PREC=0x00 TTL=49 ID=33354 DF PROTO=TCP SPT=36073 DPT=22 WINDOW=5840 RES=0x00 SYN URGP=0\n",
                 # 1 - no fragment, multi flags
                 "Jan 12 10:03:22 malloc kernel: IN=eth2 OUT= MAC= SRC=209.249.37.228 DST=10.30.245.248 LEN=40 TOS=0x00 PREC=0x00 TTL=50 ID=62210 PROTO=TCP SPT=80 DPT=58536 WINDOW=65535 RES=0x00 ACK RST URGP=0\n",
                 # 2 - no fragment, all flags, MAC address
                 "Jan 12 10:48:38 malloc kernel: IN=eth0 OUT= MAC=00:a0:cc:61:59:c1:00:10:a4:8f:cc:93:08:00 SRC=192.168.0.4 DST=192.168.0.1 LEN=40 TOS=0x00 PREC=0x00 TTL=64 ID=50000 PROTO=TCP SPT=2811 DPT=12980 WINDOW=512 RES=0x00 CWR ECE URG ACK PSH RST SYN FIN URGP=0\n",
                 # 3 - all fragment, all flags, MAC address
                 "Jan 12 10:48:38 malloc kernel: IN=eth0 OUT= MAC=00:a0:cc:61:59:c1:00:10:a4:8f:cc:93:08:00 SRC=192.168.0.4 DST=192.168.0.1 LEN=40 TOS=0x00 PREC=0x00 TTL=64 ID=50000 CE DF MF PROTO=TCP SPT=2811 DPT=12980 WINDOW=512 RES=0x00 CWR ECE URG ACK PSH RST SYN FIN URGP=0\n",

                 # UDP
                 # 4 - base
                 "Jan 12 12:07:49 malloc kernel: IN=eth2 OUT= MAC= SRC=66.150.8.30 DST=10.30.245.42 LEN=32 TOS=0x00 PREC=0x00 TTL=3 ID=1295 PROTO=UDP SPT=10890 DPT=33440 LEN=12\n",

                 # ICMP
                 # 5 - base
                 "Jan 11 22:26:49 malloc kernel: IN=eth2 OUT= MAC= SRC=66.74.32.191 DST=10.30.245.80 LEN=56 TOS=0x00 PREC=0x00 TTL=134 ID=46424 PROTO=ICMP TYPE=3 CODE=3 [SRC=10.30.245.80 DST=66.74.32.191 LEN=907 TOS=0x00 PREC=0x00 TTL=117 ID=46424 PROTO=UDP SPT=26257 DPT=1027 LEN=887 ]\n",
                 # 6 - ?
                 "Jan 12 13:09:38 malloc kernel: IN=eth2 OUT= MAC= SRC=221.143.92.216 DST=10.30.245.42 LEN=28 TOS=0x00 PREC=0x00 TTL=113 ID=37889 PROTO=ICMP TYPE=8 CODE=0 ID=512 SEQ=21039\n",
                ];


my $test = 0;
my $obj;
my $filter = POE::Filter::Log::IPTables->new(
                                             Syslog => 1,
                                             Debug => 0,
                                            );

$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth2", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, undef, "mac address");
is($obj->[0]->{ip}->{src_addr}, "192.168.50.113", "source address");
is($obj->[0]->{ip}->{dst_addr}, "10.30.245.53", "destination address");
is($obj->[0]->{ip}->{len}, "60", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "49", "ttl");
is($obj->[0]->{ip}->{id}, "33354", "id");
is_deeply($obj->[0]->{ip}->{fragment_flags}, [ "DF" ], "fragment flag");
is($obj->[0]->{ip}->{tcp}->{src_port}, "36073", "source port");
is($obj->[0]->{ip}->{tcp}->{dst_port}, "22", "dest port");
is($obj->[0]->{ip}->{tcp}->{window}, "5840", "window port");
is($obj->[0]->{ip}->{tcp}->{res}, "0x00", "res");
is_deeply($obj->[0]->{ip}->{tcp}->{flags}, [ "SYN" ], "flags");
is($obj->[0]->{ip}->{tcp}->{urgp}, "0", "urgp");
is($obj->[0]->{ip}->{tcp}->{leftover}, undef, "leftover");

$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth2", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, undef, "mac address");
is($obj->[0]->{ip}->{src_addr}, "209.249.37.228", "source address");
is($obj->[0]->{ip}->{dst_addr}, "10.30.245.248", "destination address");
is($obj->[0]->{ip}->{len}, "40", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "50", "ttl");
is($obj->[0]->{ip}->{id}, "62210", "id");
is($obj->[0]->{ip}->{fragment_flags}, undef, "fragment flag");
is($obj->[0]->{ip}->{tcp}->{src_port}, "80", "source port");
is($obj->[0]->{ip}->{tcp}->{dst_port}, "58536", "dest port");
is($obj->[0]->{ip}->{tcp}->{window}, "65535", "window port");
is($obj->[0]->{ip}->{tcp}->{res}, "0x00", "res");
is_deeply($obj->[0]->{ip}->{tcp}->{flags}, [ "ACK", "RST" ], "flags");
is($obj->[0]->{ip}->{tcp}->{urgp}, "0", "urgp");
is($obj->[0]->{ip}->{tcp}->{leftover}, undef, "leftover");

$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth0", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, "00:a0:cc:61:59:c1:00:10:a4:8f:cc:93:08:00",
   "mac address");

is($obj->[0]->{ip}->{src_addr}, "192.168.0.4", "source address");
is($obj->[0]->{ip}->{dst_addr}, "192.168.0.1", "destination address");
is($obj->[0]->{ip}->{len}, "40", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "64", "ttl");
is($obj->[0]->{ip}->{id}, "50000", "id");
is($obj->[0]->{ip}->{fragment_flags}, undef, "fragment flag");
is($obj->[0]->{ip}->{tcp}->{src_port}, "2811", "source port");
is($obj->[0]->{ip}->{tcp}->{dst_port}, "12980", "dest port");
is($obj->[0]->{ip}->{tcp}->{window}, "512", "window port");
is($obj->[0]->{ip}->{tcp}->{res}, "0x00", "res");
is_deeply($obj->[0]->{ip}->{tcp}->{flags},
          [ "CWR", "ECE", "URG", "ACK", "PSH", "RST", "SYN", "FIN" ],
          "flags");

is($obj->[0]->{ip}->{tcp}->{urgp}, "0", "urgp");
is($obj->[0]->{ip}->{tcp}->{leftover}, undef, "leftover");

$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth0", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, "00:a0:cc:61:59:c1:00:10:a4:8f:cc:93:08:00",
   "mac address");

is($obj->[0]->{ip}->{src_addr}, "192.168.0.4", "source address");
is($obj->[0]->{ip}->{dst_addr}, "192.168.0.1", "destination address");
is($obj->[0]->{ip}->{len}, "40", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "64", "ttl");
is($obj->[0]->{ip}->{id}, "50000", "id");
is_deeply($obj->[0]->{ip}->{fragment_flags},
          [ "CE", "DF", "MF" ] , "fragment flag");

is($obj->[0]->{ip}->{tcp}->{src_port}, "2811", "source port");
is($obj->[0]->{ip}->{tcp}->{dst_port}, "12980", "dest port");
is($obj->[0]->{ip}->{tcp}->{window}, "512", "window port");
is($obj->[0]->{ip}->{tcp}->{res}, "0x00", "res");
is_deeply($obj->[0]->{ip}->{tcp}->{flags},
          [ "CWR", "ECE", "URG", "ACK", "PSH", "RST", "SYN", "FIN" ],
          "flags");

is($obj->[0]->{ip}->{tcp}->{urgp}, "0", "urgp");
is($obj->[0]->{ip}->{tcp}->{leftover}, undef, "leftover");

#UDP
$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth2", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, undef, "mac address");
is($obj->[0]->{ip}->{src_addr}, "66.150.8.30", "source address");
is($obj->[0]->{ip}->{dst_addr}, "10.30.245.42", "destination address");
is($obj->[0]->{ip}->{len}, "32", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "3", "ttl");
is($obj->[0]->{ip}->{id}, "1295", "id");
is($obj->[0]->{ip}->{fragment_flags}, undef, "fragment flag");
is($obj->[0]->{ip}->{udp}->{src_port}, "10890", "source port");
is($obj->[0]->{ip}->{udp}->{dst_port}, "33440", "dest port");
is($obj->[0]->{ip}->{udp}->{len}, "12", "length");
is($obj->[0]->{ip}->{udp}->{leftover}, undef, "leftover");

#ICMP
$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth2", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, undef, "mac address");

is($obj->[0]->{ip}->{src_addr}, "66.74.32.191", "source address");
is($obj->[0]->{ip}->{dst_addr}, "10.30.245.80", "destination address");
is($obj->[0]->{ip}->{len}, "56", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "134", "ttl");
is($obj->[0]->{ip}->{id}, "46424", "id");
is($obj->[0]->{ip}->{fragment_flags}, undef, "fragment flag");

is($obj->[0]->{ip}->{icmp}->{code}, "3", "ICMP code");
is($obj->[0]->{ip}->{icmp}->{type}, "3", "ICMP type");

is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{src_addr}, "10.30.245.80",
   "error src addr");

is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{dst_addr}, "66.74.32.191",
  "error dst addr");


is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{len}, "907", "error IP len");
is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{tos}, "0x00", "error tos");
is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{prec}, "0x00", "error prec");
is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{ttl}, "117", "error ttl");
is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{id}, "46424", "error IP id");
is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{udp}->{src_port}, "26257",
   "error src port");

is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{udp}->{dst_port}, "1027",
   "error dst port");

is($obj->[0]->{ip}->{icmp}->{error_header}->{ip}->{udp}->{len}, "887", "error udp len");

is($obj->[0]->{ip}->{icmp}->{leftover}, undef, "leftover");
is($obj->[0]->{ip}->{icmp}->{error_header}->{udp}->{leftover}, undef, "leftover");

$obj = undef;
$test++;
$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth2", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, undef, "mac address");

is($obj->[0]->{ip}->{src_addr}, "221.143.92.216", "source address");
is($obj->[0]->{ip}->{dst_addr}, "10.30.245.42", "destination address");
is($obj->[0]->{ip}->{len}, "28", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "113", "ttl");
is($obj->[0]->{ip}->{id}, "37889", "id");
is($obj->[0]->{ip}->{fragment_flags}, undef, "fragment flag");

is($obj->[0]->{ip}->{icmp}->{code}, "0", "ICMP code");
is($obj->[0]->{ip}->{icmp}->{type}, "8", "ICMP type");
is($obj->[0]->{ip}->{icmp}->{id}, "512", "ICMP ID");
is($obj->[0]->{ip}->{icmp}->{seq}, "21039", "ICMP seq");

is($obj->[0]->{ip}->{icmp}->{leftover}, undef, "leftover");
