# Test correct operation of Net::Traces::TSH process_trace()
#
use strict;
use warnings;
use Test;

BEGIN {
  if ( $^O =~ m/MSWin/ ) {
    plan tests => 65
  }
  else {
    plan tests => 71
  }
};

use Net::Traces::TSH 0.14 qw(
                              process_trace configure
                              get_trace_summary_href
                              get_interfaces_href

                             );
ok(1);

process_trace 't/sample_input/sample.tsh';
ok(1);

my $trace_href = get_trace_summary_href;

ok(1);

ok($trace_href->{filename}, 't/sample_input/sample.tsh');

ok($trace_href->{IP}{Total}{Packets}, 1000);
ok($trace_href->{IP}{Total}{Bytes}, 356_422);

ok($trace_href->{IP}{Total}{Packets} =
     $trace_href->{Transport}{ICMP}{Total}{Packets}
   + $trace_href->{Transport}{TCP}{Total}{Packets}
   + $trace_href->{Transport}{UDP}{Total}{Packets}
   + $trace_href->{Transport}{Unknown}{Total}{Packets}
  );

# Similar as above, without hard-coding the transport protocols
#
my $total_transport_bytes = 0;

foreach ( keys %{ $trace_href->{Transport} } ) {
  $total_transport_bytes += $trace_href->{Transport}{$_}{Total}{Bytes}
}

ok($trace_href->{IP}{Total}{Bytes} == $total_transport_bytes);

ok($trace_href->{Transport}{TCP}{Total}{Packets}, 842);
ok($trace_href->{Transport}{TCP}{'Total ACKs'}, 576);
ok($trace_href->{Transport}{TCP}{Total}{Bytes}, 326_308);

ok($trace_href->{Transport}{UDP}{Total}{Packets}, 133);
ok($trace_href->{Transport}{UDP}{Total}{Bytes}, 28_198);

$trace_href = get_interfaces_href;

ok($trace_href->{1}{IP}{Total}{Packets}, 673);
ok($trace_href->{1}{IP}{Total}{Bytes}, 155_059);
ok($trace_href->{1}{IP}{MF}{Bytes}, undef);

ok($trace_href->{1}{Transport}{ICMP}{Total}{Packets}, 19);
ok($trace_href->{1}{Transport}{ICMP}{Total}{Bytes}, 1532);

ok($trace_href->{1}{Transport}{TCP}{'Total ACKs'}, 302);
ok($trace_href->{1}{Transport}{TCP}{'Cumulative ACKs'}, 253);
ok($trace_href->{1}{Transport}{TCP}{'Options ACKs'}, 49);
ok($trace_href->{1}{Transport}{TCP}{DF}{Bytes}, 130_332);

ok($trace_href->{1}{Transport}{TCP}{awnd}{46424}, 1);
ok($trace_href->{1}{Transport}{TCP}{rwnd}{10767}, 1);
ok($trace_href->{1}{Transport}{TCP}{rwnd}{65535}, 46);
ok($trace_href->{1}{Transport}{TCP}{SYN}{28}, 246);
ok($trace_href->{1}{Transport}{TCP}{'SYN/ACK'}{20}, 1);

ok($trace_href->{1}{Transport}{UDP}{'Packet Size'}{40}, 5);
ok($trace_href->{1}{Transport}{ICMP}{'Packet Size'}{92}, 13);

ok($trace_href->{2}{IP}{Total}{Packets}, 327);
ok($trace_href->{2}{IP}{Total}{Bytes}, 201_363);
ok($trace_href->{2}{IP}{MF}{Bytes}, undef);

ok($trace_href->{2}{Transport}{ICMP}{Total}{Packets}, 3);
ok($trace_href->{2}{Transport}{ICMP}{Total}{Bytes}, 168);

ok($trace_href->{2}{Transport}{TCP}{'Total ACKs'}, 274);
ok($trace_href->{2}{Transport}{TCP}{'Cumulative ACKs'}, 253);
ok($trace_href->{2}{Transport}{TCP}{'Options ACKs'}, 21);
ok($trace_href->{2}{Transport}{TCP}{DF}{Bytes}, 195_324);

ok($trace_href->{2}{Transport}{TCP}{rwnd}{24616}, 3);
ok($trace_href->{2}{Transport}{TCP}{awnd}{49640}, undef);

ok($trace_href->{2}{Transport}{UDP}{'Packet Size'}{38}, 1);
ok($trace_href->{2}{Transport}{TCP}{'Packet Size'}{40}, 71);
ok($trace_href->{2}{Transport}{ICMP}{'Packet Size'}{56}, 3);
ok($trace_href->{2}{IP}{'Packet Size'}{139}, 1);
ok($trace_href->{2}{Transport}{TCP}{'Packet Size'}{728}, 19);

configure(tcpdump => 't/local.tcpdump', ns2 => 't/sample.tsh');
ok($Net::Traces::TSH::options{ns2} eq 't/sample.tsh');
ok(1);

process_trace 't/sample_input/sample.tsh';
ok(1);

$trace_href = get_trace_summary_href;

ok($trace_href->{IP}{Total}{Packets}, 1000);
ok($trace_href->{IP}{Normal}{Packets}, 1000);
ok($trace_href->{IP}{'No IP Options'}{Packets}, 1000);

ok($trace_href->{Transport}{TCP}{'Total ACKs'}, 576);
ok($trace_href->{Transport}{TCP}{'Cumulative ACKs'}, 506);
ok($trace_href->{Transport}{TCP}{'Pure ACKs'}, 151);
ok($trace_href->{Transport}{TCP}{'Options ACKs'}, 70);

ok($trace_href->{Transport}{TCP}{DF}{Bytes}, 325_656);
ok($trace_href->{Transport}{TCP}{ECT}{Bytes}, 0);

ok($trace_href->{Transport}{UDP}{Normal}{Bytes}, 28198);
ok($trace_href->{Transport}{UDP}{DF}{Bytes}, 14096);

ok($trace_href->{Transport}{ICMP}{Total}{Bytes}, 1700);
ok($trace_href->{Transport}{ICMP}{DF}{Packets}, 6);
ok($trace_href->{Transport}{ICMP}{DF}{Bytes}, 336);

ok($trace_href->{Transport}{Unknown}{Total}{Bytes}, 216);
ok($trace_href->{Transport}{Unknown}{Total}{Packets}, 3);

unless ( $^O =~ m/MSWin/ ) {
  my $diff_avail = 0;

  eval {
    $diff_avail = system('diff', 't/sample_output/sample.tcpdump',
                                 't/sample_output/sample.tcpdump');
  };

  skip ( $diff_avail >> 8,
         ok( system( 'diff', 't/local.tcpdump',
                             't/sample_output/sample.tcpdump'), 0)
       );
  skip ( $diff_avail >> 8,
         ok( system( 'diff', 't/sample.tsh-if1.bin',
                             't/sample_output/sample.if-1.bin'), 0)
       );
skip ( $diff_avail >> 8,
         ok( system( 'diff', 't/sample.tsh-if2.bin',
                             't/sample_output/sample.if-2.bin'), 0)
       );

}

unlink('t/local.tcpdump');
unlink('t/sample.tsh-if1.bin');
unlink('t/sample.tsh-if2.bin');
ok(1);
