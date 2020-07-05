use Test::Most;


use aliased 'OpenTracing::Implementation::DataDog::Tracer';

use JSON::MaybeXS;

use lib 't/lib';
use UserAgent::Fake;

my $global_tracer;

subtest "Setup the tracer" => sub {
    
    my $fake_user_agent;
    lives_ok {
        $fake_user_agent = UserAgent::Fake->new;
    } "Created a 'fake_user_agent'"
    
    or return;
    
    $ENV{DD_SERVICE_NAME} = 'TAP::Harness';
    
    lives_ok {
        $global_tracer = Tracer->new(
            client => {
                http_user_agent => $fake_user_agent
            },
            default_resource_name  => __FILE__,
        )
    } "Created a Tracer,"
    
    or return;
    
};

subtest "Create spans as if it is manual instrumentation" => sub {
    
    sub zero {
        my $scope = $global_tracer->start_active_span( 'zero' );
        one_a();
        one_b();
        $scope->close;
    }
    
    sub one_a {
        my $scope = $global_tracer->start_active_span( 'one_a' );
        two();
        $scope->close;
    }
    
    sub one_b {
        my $scope = $global_tracer->start_active_span( 'one_b' );
        two();
        two();
        $scope->close;
    }
    
    sub two {
        my $scope = $global_tracer->start_active_span( 'two' );
        # do nothing
        $scope->close;
    }
    
    lives_ok{ zero() } "Did run some subroutines"
    
};

subtest "Check the requests" => sub {
    
    my @requests = $global_tracer->client->http_user_agent->get_all_requests();
    
    my @structs = map {
        decode_json( $_->decoded_content )
    } @requests;
    
    cmp_deeply(
        \@structs =>
        [
            [[ superhashof { name => 'two'   } ]],
            [[ superhashof { name => 'one_a' } ]],
            [[ superhashof { name => 'two'   } ]],
            [[ superhashof { name => 'two'   } ]],
            [[ superhashof { name => 'one_b' } ]],
            [[ superhashof { name => 'zero'  } ]],
        ],
        "Got the right spans in the expected order"
    );
    
};

done_testing();
