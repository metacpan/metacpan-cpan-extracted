use Test::Most;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



subtest "Instantiation of Span and Tags" => sub {
    
    # get_tags returns a plain hash, not a hash reference
    
    cmp_deeply(
        {
            MyStub::Span->new(
                operation_name => 'test',
                context        => bless( {}, 'MyStub::SpanContext' ),
                child_of       => bless( {}, 'MyStub::Span' ),
            )->get_tags( )
        },
        { },
        "By default, there are no tags"
    );
    
    cmp_deeply(
        {
            MyStub::Span->new(
                operation_name => 'test',
                context        => bless( {}, 'MyStub::SpanContext' ),
                child_of       => bless( {}, 'MyStub::Span' ),
                tags           => { key1 => 'foo', key2 => 'bar' },
            )->get_tags( )
        },
        {
            key1 => 'foo',
            key2 => 'bar',
        },
        "Tags can be provided at instantiation"
    );
    
};



subtest "Setting tags" => sub {
    
    cmp_deeply(
        {
            MyStub::Span->new(
                operation_name => 'test',
                context        => bless( {}, 'MyStub::SpanContext' ),
                child_of       => bless( {}, 'MyStub::Span' ),
            )->add_tag(
                key3 => 'baz'
            )->get_tags( )
        },
        {
            key3 => 'baz',
        },
        "Can set additional tag"
    );
    
    cmp_deeply(
        {
            MyStub::Span->new(
                operation_name => 'test',
                context        => bless( {}, 'MyStub::SpanContext' ),
                child_of       => bless( {}, 'MyStub::Span' ),
                tags           => { key1 => 'foo', key2 => 'bar' },
            )->add_tag(
                key1 => 'qux',
            )->get_tags( )
        },
        {
            key1 => 'qux',
            key2 => 'bar',
        },
        "Will overwrite already existing tag... it's called 'add_tag'"
    );
    
    cmp_deeply(
        {
            MyStub::Span->new(
                operation_name => 'test',
                context        => bless( {}, 'MyStub::SpanContext' ),
                child_of       => bless( {}, 'MyStub::Span' ),
                tags           => { key1 => 'foo', key2 => 'bar' },
            )->add_tags(
                key1 => 'qux',
                key3 => 'foo',
            )->get_tags( )
        },
        {
            key1 => 'qux',
            key2 => 'bar',
            key3 => 'foo',
        },
        "Works okay with mutiply key/value pairs when calling 'add_tags'"
    );
    
};



done_testing();



package MyStub::Span;

use Moo;

BEGIN { with 'OpenTracing::Role::Span' }



package MyStub::SpanContext;

use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext' }



1;
