use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib ('t/lib');

use TestAPI;

ok my $api = TestAPI->new(), 'api object created';

for my $role (qw/UserAgent Format Authentication Serialization Request/) {
    ok $api->meta->does_role('Net::HTTP::API::Role::' . $role),
      'does role ' . $role;
}

# test fetch list of users
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        is $request->method, 'GET', 'GET request';
        my $res = HTTP::Response->new(200);
        $res->content('[{"name":"eris"}]');
        $res;
    }
);

ok my ($content, $res) = $api->users(), 'api call success';
is $res->code, 200, 'http code as expected';
is_deeply $content, [{name => 'eris'}], 'got a list of users';

# test fetch list of one user
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        is $request->method, 'GET', 'GET request';
        is $request->uri, 'http://exemple.com/user/eris.json',
          'valid url generated';
        my $res = HTTP::Response->new(200);
        $res->content('{"name":"eris"}');
        $res;
    }
);

ok $content = $api->user(user_name => 'eris'), 'api call success';
is_deeply $content, {name => 'eris'}, 'valid user content';

# test to create a user
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        is $request->method, 'POST', 'POST request';
        is $request->content,
          JSON::encode_json({name => 'eris', dob => '01/02/1900'}),
          'got valid content in POST';
        my $res = HTTP::Response->new(201);
        $res->content('{"status":"ok"}');
        $res;
    }
);

($content, $res) = $api->add_user(name => 'eris', dob => '01/02/1900');
ok $content, 'got content';
is $res->code, 201, 'code as expected';

# test to update a user
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        my $res     = HTTP::Response->new(201);
        $res->content('{"status":"ok"}');
        $res;
    }
);

($content, $res) = $api->update_user(name => 'eris', dob => '02/01/1900');
ok $content, 'got content after update';
is $res->code, 201, 'code as expected';

# test to delete a user
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub{
        my $request = shift;
        my $res = HTTP::Response->new(204);
        $res;
    }
);

($content, $res) = $api->delete_user(name => 'eris');
is $res->code, 204, 'code as expected';

# unstrict parameters
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        my $res = HTTP::Response->new(200);
        $res;
    }
);

($content, $res) = $api->unstrict_users(
    name         => 'eris',
    last_name    => 'foo',
    random_stuff => 'bar'
);
is $res->code, 200, 'code as expected';
is $res->request->uri,
  'http://exemple.com/users/unstrict.json?random_stuff=bar&name=eris&last_name=foo',
  'url is ok with no declared parameters';

# params in url and body
$api->api_useragent->remove_handler('request_send');
$api->api_useragent->add_handler(
    'request_send' => sub {
        my $request = shift;
        my $res = HTTP::Response->new(200);
        $res;
    }
);

($content, $res) = $api->params_users(name => 'eris', bod => '01/01/1970');
is $res->code, 200, 'code as expected';
is $res->request->uri, 'http://exemple.com/users.json?bod=01%2F01%2F1970', 'url is ok';

done_testing;
