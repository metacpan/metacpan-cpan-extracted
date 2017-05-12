use Test::More tests => 7;

BEGIN { use_ok('Net::Traces::SSFNet') };

ok( Net::Traces::SSFNet::droptail_assert_input( 't/sample_queue_trace.0', 'some_stream_id.0'), 'Assert valid traces' );

is( Net::Traces::SSFNet::droptail_assert_input( 't/sample_queue_trace.0' ), 'some_stream_id.0', 'Assert valid trace and return stream ID' );

is(($Net::Traces::SSFNet::PRINT_EXACT_DECIMAL_DIGITS = 0), 0);
is(($Net::Traces::SSFNet::PRINT_EXACT_DECIMAL_DIGITS = 1), 1);
is(($Net::Traces::SSFNet::SHOW_STATS = 0), 0);

is( Net::Traces::SSFNet::droptail_record_player( 't/sample_queue_trace.0', '/dev/null', 'some_stream_id.0' ) , 21, 'Validate trace processing' );
