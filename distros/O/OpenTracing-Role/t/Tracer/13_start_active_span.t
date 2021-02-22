use Test::Most;
use Test::Deep qw/true false/;
use Test::MockObject::Extends;

$ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



subtest "Pass through to 'start_span' with known options" => sub {
    
    my ( $call_name, $call_args);
    
    my $stub_scope_manager = Test::MockObject::Extends->new(
        MyStub::ScopeManager->new()
    )->mock( 'activate_span' =>
        sub { bless {}, 'MyStub::Scope' }
    );
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => $stub_scope_manager,
        )
    )->mock( 'start_span' =>
        sub { bless {}, 'MyStub::Span' }
    );
    
    my $some_span_context  = bless {}, 'MyStub::SpanContext';
    
    
    
    lives_ok {
        $mock_tracer
            ->start_active_span( 'some operation name',
                ignore_active_span   => 1,
                child_of             => $some_span_context,
                start_time           => 1.25,
                tags                 => { foo => 1, bar => 6 },
                finish_span_on_close => 1,
            )->close;
    } "Can call 'start_active_span' with known options";
    
    
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    is( $call_name, 'start_span',
        "... and did pass on to 'start_span'"
    );
    
    is( shift @{$call_args}, $mock_tracer,
        "... with the invocant is the 'MyStub::Tracer'"
    );
    
    is( shift @{$call_args}, "some operation name",
        "... with the operation_name as first argument"
    );
    
    cmp_deeply(
        { @{$call_args} },
        {
            ignore_active_span => 1,
            child_of           => $some_span_context,
            start_time         => 1.25,
            tags               => { foo => 1, bar => 6 },
        },
        "... with the expected remaining options"
    ); # that is, without 'finish_span_on_close, see below
    
};



subtest "Pass through to 'start_span' without any options" => sub {
    
    my ($call_name, $call_args);
    
    my $stub_scope_manager = Test::MockObject::Extends->new(
        MyStub::ScopeManager->new()
    )->mock( 'activate_span' =>
        sub { bless {}, 'MyStub::Scope' }
    );
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => $stub_scope_manager,
        )
    )->mock( 'start_span' =>
        sub { bless {}, 'MyStub::Span' }
    );
    
    
    
    lives_ok {
        $mock_tracer
            ->start_active_span( 'next operation name',
        )->close;
    } "Can call 'start_active_span' without any options";
    
    ($call_name, $call_args) = $mock_tracer->next_call();
    
    is( $call_name, 'start_span',
        "... and did pass on to 'start_span'"
    );
    
    is( shift @{$call_args}, $mock_tracer,
        "... with the invocant is the 'MyStub::Tracer'"
    );
    
    is( shift @{$call_args}, "next operation name",
        "... with the operation_name as first argument"
    );
    
    cmp_deeply(
        { @{$call_args} },
        { },
        "... without introducing default options"
    );
    
};

subtest "Private option 'finish_span_on_close'" => sub {
    

    my ($call_name, $call_args);
    
    my $some_span = bless {}, 'MyStub::Span';
    
    my $mock_scope_manager = Test::MockObject::Extends->new(
        MyStub::ScopeManager->new()
    )->mock( 'activate_span' =>
        sub { bless {}, 'MyStub::Scope' }
    );
    
    my $mock_tracer = Test::MockObject::Extends->new(
        MyStub::Tracer->new(
            scope_manager => $mock_scope_manager,
        )
    )->mock( 'start_span' =>
        sub {
            $some_span
        }
    );
    
    
    
    lives_ok {
        $mock_tracer
            ->start_active_span( 'this operation name',
        )->close;
    } "Can call 'start_active_span' without 'finish_span_on_close'";
    
    ($call_name, $call_args) = $mock_scope_manager->next_call();
    
#   is( $call_name, 'activate_span',
#       "... and did pass on to 'activate_span'"
#   );
    
    is( shift @{$call_args}, $mock_scope_manager,
        "... with the invocant is the 'MyStub::ScopeManager'"
    );
    
    is( shift @{$call_args}, $some_span,
        "... with the 'MyStub::Span' from previous call"
    );
    
    cmp_deeply(
        { @{$call_args} },
        {
            finish_span_on_close => true,
        },
        "... with default 'finish_span_on_close' set to 'true'"
    );
    
    
    
    lives_ok {
        $mock_tracer
            ->start_active_span( 'that operation name',
            finish_span_on_close => 1,
        )->close;
    } "Can call 'start_active_span' with 'finish_span_on_close' set to 'true'";
    
    ($call_name, $call_args) = $mock_scope_manager->next_call();
    
    shift @{$call_args}; # invocant
    shift @{$call_args}; # span
    
    cmp_deeply(
        { @{$call_args} },
        {
            finish_span_on_close => true,
        },
        "... with pass on 'finish_span_on_close' set to 'true'"
    );
    
    
    
    lives_ok {
        $mock_tracer
            ->start_active_span( 'last operation name',
            finish_span_on_close => 0,
        )->close;
    } "Can call 'start_active_span' with 'finish_span_on_close' set to 'false'";
    
    ($call_name, $call_args) = $mock_scope_manager->next_call();
    
    shift @{$call_args}; # invocant
    shift @{$call_args}; # span
    
    cmp_deeply(
        { @{$call_args} },
        {
            finish_span_on_close => false,
        },
        "... with pass on 'finish_span_on_close' set to 'false'"
    );
   
};



done_testing();



# MyStub::...
#
# The following packages are stubs with minimal implementation that only
# satisfy required subroutines so roles can be applied.
# Any subroutines under testing probably need mocking
# Test::MockObject::Extends is your friend

package MyStub::Tracer;
use Moo;

sub build_span                           { ... }
sub build_context                        { ... }
sub inject_context_into_array_reference  { ... }
sub extract_context_from_array_reference { ... }
sub inject_context_into_hash_reference   { ... }
sub extract_context_from_hash_reference  { ... }
sub inject_context_into_http_headers     { ... }
sub extract_context_from_http_headers    { ... }

BEGIN { with 'OpenTracing::Role::Tracer'; }



package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span'; }



package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext'; }



package MyStub::Scope;
use Moo;

sub close { $_[0]->_set_closed( !undef); $_[0] }

BEGIN { with 'OpenTracing::Role::Scope'; }



package MyStub::ScopeManager;
use Moo;

sub build_scope { ... };

BEGIN { with 'OpenTracing::Role::ScopeManager'; }






1;
