#!perl -T
use strict;
use Test::More;
use Net::Pcap;

plan tests => 3;

# ---[ copied from Pcap.pm ]----------------------------------------------------
# functions names
my @func_short_names = qw(
    lookupdev  findalldevs  lookupnet
    open_live  open_dead  open_offline  loop  breakloop  close  dispatch
    next  next_ex  compile  compile_nopcap  setfilter  freecode
    offline_filter  setnonblock  getnonblock
    dump_open  dump  dump_file  dump_flush  dump_close
    datalink  set_datalink  datalink_name_to_val  datalink_val_to_name
    datalink_val_to_description
    snapshot  is_swapped  major_version  minor_version  stats
    file  fileno  get_selectable_fd  geterr  strerror  perror
    lib_version  createsrcstr  parsesrcstr  open  setbuff  setuserbuffer
    setmode  setmintocopy  getevent  sendpacket
    sendqueue_alloc  sendqueue_queue  sendqueue_transmit
);

my @func_long_names = map { "pcap_$_" } @func_short_names;
# ------------------------------------------------------------------------------

# check that the following functions are available (old API)
can_ok( "Net::Pcap", @func_short_names );

# check that the following functions are available (new API)
can_ok( "Net::Pcap", @func_long_names );

# check that the following functions are available (new API)
can_ok( __PACKAGE__, @func_long_names );

