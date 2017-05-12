# Test correct operation of Net::Traces::TSH process_trace()
#
use strict;
use Test;

BEGIN {
  if ( $^O =~ m/MSWin/ ) {
    plan tests => 3;
  }
  else {
    plan tests => 7;
  }
 };
use Net::Traces::TSH 0.16 qw(
	                      process_trace
                              write_interface_summaries
                              get_interfaces_href
                              get_interfaces_list
                            );
ok(1);

process_trace 't/sample_input/sample.tsh';
ok(1);

write_interface_summaries;
ok(1);

unless ( $^O =~ m/MSWin/ ) {
  my $diff_avail = 0;

  eval {
    $diff_avail = system( 'diff', 't/sample_output/sample.csv',
                                  't/sample_output/sample.csv'
                        );
  };

  while ( ($_) = each %{get_interfaces_href()} ) {
    skip ( $diff_avail >> 8, 
           ok( system( 'diff',
                       "t/sample_input/sample.tsh.if-$_.csv",
                       "t/sample_output/sample.if-$_.csv"), 0 )
         );
  }
  #unlink(<t/sample_input/sample.tsh.if-*.csv>);
}
