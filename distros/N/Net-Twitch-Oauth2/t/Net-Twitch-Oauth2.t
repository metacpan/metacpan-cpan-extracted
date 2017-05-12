use warnings;
use strict;
use Net::Twitch::Oauth2;
use Test::More;

#########################
#########################
# Fixture Data
my $app_id       = 'testapp_id';
my $app_secret   = 'test_app_secret';
my $access_token = 'test_access_token';
my $url          = 'test.www.com';
my $class = 'Net::Twitch::Oauth2';

eval "use Test::Requires qw/Test::Exception Test::MockObject Test::MockModule/";
if ($@){
    plan skip_all => 'Test::Requires required for testing';
} else {
    
    #had to re use??!
    use Test::Exception;
    use Test::MockObject;
    use Test::MockModule;

    can_instantiate_class();
    test_get_method_with_no_browser_parameter();
    can_pass_browser_param();
    can_do_delete_request();
    done_testing();
}


sub can_instantiate_class {

    my $net_twitch_oauth2 = $class->new(
        application_id     => $app_id,
        application_secret => $app_secret,
    );

    ok $net_twitch_oauth2,
      "Can instantiate $class with application_id and application_secret";

    dies_ok { $class->new( application_id => $app_id ) }
     'Dies if no application_secret passed to constructor';

    dies_ok { $class->new( application_secret => $app_secret ) }
     'Dies if no application_id passed to constructor';
}

sub test_get_method_with_no_browser_parameter {

    # Test that browser attribute is LWP::UserAgent if no browser param passed

    my $test_json    = '{"data":"this is the get data"}';

    my $mock_get_response = _mock_object(
        {
            is_success => 1,
            content    => $test_json,
        }
    );

    # Mock LWP::UserAgent methods so can test offline
    my $mock_user_agent = _mock_object(
        {
            get => $mock_get_response,
        }
    );

    my $mock_user_agent_module = new Test::MockModule('LWP::UserAgent');
    $mock_user_agent_module->mock( 'new', sub {return $mock_user_agent;} );

    my $net_twitch_oauth2 = $class->new(
        application_id     => $app_id,
        application_secret => $app_secret,
        access_token       => $access_token,
    );

    is $net_twitch_oauth2->get( $url )->as_json, $test_json,
        'Passing no browser param will use LWP::UserAgent';
}

sub can_pass_browser_param {

    my $test_json    = '{"data":"this is the get data"}';

    my $mock_get_response = _mock_object(
        {
            is_success => 1,
            content    => $test_json,
        }
    );

    my $mock_browser = _mock_object( {
            get => $mock_get_response,
        }
    );

    my $net_twitch_oauth2 = $class->new(
        application_id     => $app_id,
        application_secret => $app_secret,
        access_token       => $access_token,
        browser            => $mock_browser,
    );

    is $net_twitch_oauth2->get( $url )->as_json, $test_json,
        'Can pass browser param';
}

sub can_do_delete_request {
    my $test_json    = '{"data":"this is the delete data"}';

    my $mock_delete_response = _mock_object(
        {
            is_success => 1,
            content    => $test_json,
        }
    );

    # Mock LWP::UserAgent methods so can test offline
    my $mock_user_agent = _mock_object(
        {
            delete => $mock_delete_response,
        }
    );

    my $mock_user_agent_module = new Test::MockModule('LWP::UserAgent');
    $mock_user_agent_module->mock( 'new', sub {return $mock_user_agent;} );

    my $net_twitch_oauth2 = $class->new(
        application_id     => $app_id,
        application_secret => $app_secret,
        access_token       => $access_token,
    );

    is $net_twitch_oauth2->delete( $url )->as_json, $test_json,
    'Delete request returns correct JSON';
}

sub _mock_object {
    my $mock_kv = shift;
    my $mock_object = Test::MockObject->new;
    while ( my($key, $value) = each %$mock_kv) {
        $mock_object->set_always($key, $value);
    }
    return $mock_object;
}