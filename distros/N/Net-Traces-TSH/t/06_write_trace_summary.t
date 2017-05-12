# Test correct operation of Net::Traces::TSH process_trace()
#
use strict;
use Test;

BEGIN { 
  if ( $^O =~ m/MSWin/ ) {
    plan tests => 4
  }
  else {
    plan tests => 6
  }
};
use Net::Traces::TSH 0.14 qw( process_trace write_trace_summary);
ok(1);

process_trace 't/sample_input/sample.tsh';
ok(1);

write_trace_summary;
ok(1);

unless ( $^O =~ m/MSWin/ ) {
  my $diff_avail = 0;

  eval {
    $diff_avail = system('diff', 't/sample_output/sample.csv',
                                 't/sample_output/sample.csv');
  };

  skip ( $diff_avail >> 8, 
         ok( system('diff', 't/sample_input/sample.tsh.csv',
                            't/sample_output/sample.csv'), 0)
       );
}

#unlink('t/sample_input/sample.tsh.csv');
ok(1);

