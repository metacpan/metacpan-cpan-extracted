use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 7;

use Plack::Request;
use Try::Tiny;
use TestDataHandler;
use OAuth::Lite2::Server::GrantHandler::GroupingRefreshToken;
use OAuth::Lite2::Util qw(build_content);

TestDataHandler->clear;
# authorized client
TestDataHandler->add_client(
    id => q{authzed_client}, 
    secret => q{authzed_client_secret}, 
    user_id => 1, 
    group_id => 1 , 
);
TestDataHandler->add_client(
    id => q{authzed_client_2}, 
    secret => q{authzed_client_secret_2}, 
    user_id => 1,
);

# not authorized client
TestDataHandler->add_client(
    id => q{not_authzed_client}, 
    secret => q{not_authzed_client_secret}, 
    user_id => 1, 
    group_id => 1
);
TestDataHandler->add_client(
    id => q{not_authzed_client_for_no_group}, 
    secret => q{not_authzed_client_secret}, 
    user_id => 1, 
);
TestDataHandler->add_client(
    id => q{not_authzed_client_for_another_group}, 
    secret => q{not_authzed_client_secret}, 
    user_id => 1, 
    group_id => 2
);

my $dh = TestDataHandler->new;

my $action = OAuth::Lite2::Server::GrantHandler::GroupingRefreshToken->new;

sub test_success {
    my $params = shift;
    my $expected = shift;
    my $request = Plack::Request->new({
        REQUEST_URI    => q{http://example.org/token},
        REQUEST_METHOD => q{POST},
        QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my $res; try {
        $res = $action->handle_request($dh);
    } catch {
        my $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };
    is($res->{refresh_token}, $expected->{refresh_token});
}

sub test_error {
    my $params = shift;
    my $message = shift;
    my $request = Plack::Request->new({
        REQUEST_URI    => q{http://example.org/resource},
        REQUEST_METHOD => q{GET},
        QUERY_STRING   => build_content($params),
    });
    my $dh = TestDataHandler->new(request => $request);
    my $error_message; 
    try {
        my $res = $action->handle_request($dh);
    } catch {
        $error_message = ($_->isa("OAuth::Lite2::Error"))
            ? $_->type : $_;
    };

    is($error_message, $message->{message});
}

my $auth_info = $dh->create_or_update_auth_info(
    client_id => q{authzed_client},
    user_id   => q{1},
);

&test_success({
    client_id           => q{not_authzed_client},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => $auth_info->refresh_token,
    scope               => q{grouping_scope},   
}, {
    refresh_token   => q{refresh_token_1},
});

&test_error({
    client_id           => q{not_authzed_client},    
    client_secret       => q{not_authzed_client_secret},
},{ 
    message             => q{invalid_request: 'refresh_token' not found},
});

&test_error({
    client_id           => q{not_authzed_client},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => q{invalid_refresh_token},
},{ 
    message             => q{invalid_grant: 'refresh_token' is invalid},
});

my $auth_info_2 = $dh->create_or_update_auth_info(
    client_id => q{authzed_client_2},
    user_id   => q{1},
);

&test_error({
    client_id           => q{not_authzed_client},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => $auth_info_2->refresh_token,
},{ 
    message             => q{invalid_grant: 'refresh_token' does not have group id},
});

&test_error({
    client_id           => q{not_authzed_client_for_no_group},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => $auth_info->refresh_token,
},{ 
    message             => q{invalid_client: 'client_id' does not have group id},
});

&test_error({
    client_id           => q{not_authzed_client_for_another_group},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => $auth_info->refresh_token,
},{ 
    message             => q{invalid_request: group id does not match},
});

&test_error({
    client_id           => q{not_authzed_client},    
    client_secret       => q{not_authzed_client_secret},
    refresh_token       => $auth_info->refresh_token,
    scope               => q{invalid_scope},
},{ 
    message             => q{invalid_scope: },
});
