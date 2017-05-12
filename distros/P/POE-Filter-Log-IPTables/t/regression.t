# -*- mode: cperl; cperl-indent-level: 4; -*-
# vi:ai:sm:et:sw=4:ts=4

# $Id: regression.t,v 1.2 2005/11/18 23:37:12 paulv Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Filter-Log-IPTables.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More qw(no_plan);
use Data::Dumper;
use Test::More tests => 13;
BEGIN { use_ok('IPTables') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $test_data = [
                 "Nov 17 12:56:14 nn-n.nnn_nn kernel: IN=eth1 OUT= MAC=01:00:5e:00:00:01:00:0c:41:d2:11:0b:08:00 SRC=192.168.1.2 DST=224.0.0.1 LEN=28 TOS=0x00 PREC=0x00 TTL=1 ID=0 DF PROTO=2\n",
                ];


my $test = 0;
my $obj;
my $filter = POE::Filter::Log::IPTables->new(
                                             Syslog => 1,
                                             Debug => 0,
                                            );

$obj = $filter->get([ $test_data->[$test] ]);

is($obj->[0]->{in_int}, "eth1", "in interface");
is($obj->[0]->{out_int}, undef, "out interface");
is($obj->[0]->{mac}, "01:00:5e:00:00:01:00:0c:41:d2:11:0b:08:00", "mac address");
is($obj->[0]->{ip}->{src_addr}, "192.168.1.2", "source address");
is($obj->[0]->{ip}->{dst_addr}, "224.0.0.1", "destination address");
is($obj->[0]->{ip}->{len}, "28", "length");
is($obj->[0]->{ip}->{tos}, "0x00", "tos");
is($obj->[0]->{ip}->{prec}, "0x00", "prec");
is($obj->[0]->{ip}->{ttl}, "1", "ttl");
is($obj->[0]->{ip}->{id}, "0", "id");
is_deeply($obj->[0]->{ip}->{fragment_flags}, [ "DF" ], "fragment flags");
is($obj->[0]->{ip}->{type}, "igmp", "proto");
