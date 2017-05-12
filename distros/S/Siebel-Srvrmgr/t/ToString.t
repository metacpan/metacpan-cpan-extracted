use warnings;
use strict;
use Test::Most tests => 7;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Test::Output 1.03;
use Regexp::Common 0.07 qw(time);
use lib 't';
use Test::Siebel::Srvrmgr::Fixtures qw(create_comp);

my $time_zone = 'America/Sao_Paulo';
note(
"Configuring time zone to $time_zone in order to properly configure the Comp object"
);
local $ENV{SIEBEL_TZ} = $time_zone;
my $comp = create_comp();
can_ok( $comp, qw(to_string_header to_string) );
dies_ok { $comp->to_string_header }
'to_string_header expects a separator as parameter';
like( $@, qr/separator must be a single character/,
    'exception is as expected' );
dies_ok { $comp->to_string } 'to_string expects a separator as parameter';
like( $@, qr/separator must be a single character/,
    'exception is as expected' );
my $header =
q{actv_mts_procs#alias#cg_alias#ct_alias#curr_datetime#desc_text#disp_run_state#end_datetime#incarn_no#max_mts_procs#max_tasks#name#num_run_tasks#run_mode#start_datetime#start_mode#status#time_zone};
stdout_is { print $comp->to_string_header('#') } $header,
  'to_string_header prints the expected text';
my $body =
qr#1|SRProc|Server Request Processor|SRProc|$RE{time}{iso}||Shutdown|$RE{time}{iso}|0|1|20|Server Request Processor|0|Interactive|$RE{time}{iso}|Enabled|America/Sao_Paulo#;
stdout_like { print $comp->to_string('|') } $body,
  'to_string prints the expected text';
