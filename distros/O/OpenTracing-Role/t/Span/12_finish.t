use Test::Most;


$ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



use Test::Time::HiRes;



subtest "Default behaviour" => sub {
    
    my $test_span;
    
    $test_span = MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    );
    
    Test::Time::HiRes->set_time( 256.875 );
    
    lives_ok {
        $test_span->finish( );
    } "Can finish a Span without timestamp";
    
    is $test_span->finish_time +0, 256.875,
        "... and has the correct finish_time";
    
};



subtest "Explicit finish time" => sub {
    
    my $test_span;
    
    $test_span = MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    );
    
    Test::Time::HiRes->set_time( 256.875 );
    
    lives_ok {
        $test_span->finish( 128.125 );
    } "Can finish a Span without explicit timestamp";
    
    is $test_span->finish_time +0, 128.125,
        "... and has the correct finish_time";
    
};



subtest "Finishing only once" => sub {
    
    my $test_span;
    
    $test_span = MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    );
    
    ok ! $test_span->has_finished(),
        "Span has not been finished yet";
    
    $test_span->finish( );
    
    ok $test_span->has_finished(),
        "... but has, after 'finish' has been called";
    
    warning_like {
        $test_span->finish( )
    } qr/Span has already been finished/,
        "... and can not 'finish' again";
    
};



subtest "Finishing blocks other methods" => sub {
    
    my $test_span;
    
    $test_span = MyStub::Span->new(
        operation_name => 'test',
        context        => bless( {}, 'MyStub::SpanContext' ),
        child_of       => bless( {}, 'MyStub::Span' ),
    )->finish;
    
    ok $test_span->has_finished(),
        "Span has finished";
    
    throws_ok {
        $test_span->overwrite_operation_name( 'foo' )
    } qr/.* finished span/,
        "... and can not call 'overwrite_operation_name'";
    
    throws_ok {
        $test_span->add_tag( foo => 'bar' )
    } qr/.* finished span/,
        "... and can not call 'add_tag'";
    
    throws_ok {
        $test_span->log_data( key1 => 'value1', key2 => 'value2' )
    } qr/.* finished span/,
        "... and can not call 'log_data'";
    
    throws_ok {
        $test_span->add_baggage_item( foo => 'bar' )
    } qr/.* finished span/,
        "... and can not call 'add_baggage_item'";
    
    throws_ok {
        $test_span->add_baggage_items( key1 => 'value1', key2 => 'value2' )
    } qr/.* finished span/,
        "... and can not call 'add_baggage_items'";
    
};



done_testing();



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span' }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext' }



1;
