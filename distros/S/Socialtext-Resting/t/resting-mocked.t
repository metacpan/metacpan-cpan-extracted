#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 177;
use Test::Mock::LWP;

BEGIN {
    use_ok 'Socialtext::Resting';
}

my %rester_opts = (
    username => 'test-user@example.com',
    password => 'passw0rd',
    server   => 'http://www.socialtext.net',
    workspace => 'st-rest-test',
);

sub new_strutter {
    $Mock_ua->clear;
    $Mock_req->clear;
    $Mock_resp->clear;
    return Socialtext::Resting->new(%rester_opts);
}

Get_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'bar');
    is $rester->get_page('Foo'), 'bar';
    result_ok(
        uri  => '/pages/foo',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/x.socialtext-wiki' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'etag' ],
        ],
    );
}

Get_json_verbose_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'bar');
    $rester->json_verbose(1);
    $rester->accept('application/json');
    is $rester->get_page('Foo'), 'bar';
    result_ok(
        uri  => '/pages/foo?verbose=1',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'application/json' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'etag' ],
        ],
    );
}

Get_page_fails: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'no auth');
    $Mock_resp->set_always('code', 403);
    eval { $rester->get_page('Foo') };
    like $@, qr/403: no auth/;
}

Put_new_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 201);
    $rester->put_page('Foo', 'bar');
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'header' => 'Content-Length' => 3 ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Put_existing_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    $rester->put_page('Foo', 'bar');
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'header' => 'Content-Length' => 3 ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}


Put_existing_page_json: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    $rester->put_page(
        'Foo' => {
            content => 'bar',
        }
    );
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'application/json' ],
            [ 'header' => 'Content-Length' => 17 ],
            [ 'content' => '{"content":"bar"}' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Put_page_fails: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', 'no auth');
    $Mock_resp->set_always('code', 403);
    eval { $rester->put_page('Foo', 'bar') };
    like $@, qr/403: no auth/;
}

Post_attachment: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    local $Test::Mock::HTTP::Response::Headers{location} = 'waa';
    $rester->post_attachment('Foo', 'bar.txt', 'bar', 'text/plain');
    result_ok(
        uri  => '/pages/foo/attachments?name=bar.txt',
        method => 'POST',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/plain' ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'location' ],
        ],
    );
}

Put_tag: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    $rester->put_pagetag('Foo', 'taggy');
    result_ok(
        uri  => '/pages/foo/tags/taggy',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Length' => 0 ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Collision_detection: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 200);
    $Mock_resp->set_always('content', 'bar');
    local $Test::Mock::HTTP::Response::Headers{etag} = '20070118070342';
    $rester->get_page('Foo'); # should store etag
    result_ok(
        uri  => '/pages/foo',
        method => 'GET',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/x.socialtext-wiki' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'etag' ],
        ],
    );
    $Mock_resp->set_always('content', 'precondition failed');
    $Mock_resp->set_always('code', 412);
    eval { $rester->put_page('Foo', 'bar') };
    like $@, qr/412: precondition failed/;
    result_ok(
        uri  => '/pages/Foo',
        method => 'PUT',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'header' => 'If-Match', $Test::Mock::HTTP::Response::Headers{etag} ],
            [ 'header' => 'Content-Length' => 3 ],
            [ 'content' => 'bar' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
    $Mock_resp->set_always('code', 200);
}

Get_revisions: {
    my $rester = new_strutter();
    $rester->accept('text/plain');
    $Mock_resp->set_always('content', 'bar');
    $rester->get_revisions('foo');
    result_ok(
        uri  => '/pages/foo/revisions',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/plain' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Tag_a_person: {
    my $rester = new_strutter();
    $rester->put_persontag('test@example.com', 'foo');
    result_ok(
        uri  => 'people/test%40example.com/tags',
        no_workspace => 1,
        method => 'POST',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type' => 'application/json' ],
            [ 'content' => '{"tag_name":"foo"}' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Get_signals: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', "This\nThat");
    $rester->get_signals();
    result_ok(
        no_workspace => 1,
        uri  => 'signals',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/plain' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Get_signals_w_args: {
    my $rester = new_strutter();
    $Mock_resp->set_always('content', "This\nThat");
    $rester->get_signals(account_id => 2);
    result_ok(
        no_workspace => 1,
        uri  => 'signals?account_id=2',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Accept', 'text/plain' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
        ],
    );
}

Post_signal: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    local $Test::Mock::HTTP::Response::Headers{location} = 'waa';
    $rester->post_signal('O HAI');
    result_ok(
        no_workspace => 1,
        uri  => 'signals',
        method => 'POST',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username},
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'application/json' ],
            [ 'content' => '{"signal":"O HAI"}' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'location' ],
        ],
    );
}

Post_signal_to_group: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 204);
    local $Test::Mock::HTTP::Response::Headers{location} = 'waa';
    $rester->post_signal('O HAI', group_id => 42, account_ids => [2,3,4]);
    result_ok(
        no_workspace => 1,
        uri  => 'signals',
        method => 'POST',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username},
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'application/json' ],
            [ 'content' =>
                '{"signal":"O HAI","group_ids":[42],"account_ids":[2,3,4]}' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'header' => 'location' ],
        ],
    );
}

Delete_page: {
    my $rester = new_strutter();
    $Mock_resp->set_always('code', 201);
    $rester->put_page('Foo', 'bar');
    $Mock_resp->set_always('code', 204);
    $rester->delete_page('Foo');
    result_ok(
        uri  => '/pages/Foo',
        method => 'DELETE',
        ua_calls => [
            [ 'simple_request' => $Mock_req ],
            [ 'simple_request' => $Mock_req ],
        ],
        req_calls => [
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'text/x.socialtext-wiki' ],
            [ 'header' => 'Content-Length' => 3 ],
            [ 'content' => 'bar' ],
            [ 'authorization_basic' => $rester_opts{username}, 
              $rester_opts{password},
            ],
            [ 'header' => 'Content-Type', 'application/json' ],
            [ 'content' => '{}' ],
        ],
        resp_calls => [
            [ 'code' ],
            [ 'content' ],
            [ 'code' ],
            [ 'content' ],
        ],
    );
}
exit; 

sub result_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %args = (
        method => 'GET',
        ua_calls => [],
        req_calls => [],
        resp_calls => [],
        @_,
    );
    my $prefix = $args{no_workspace}
        ? 'data/'
        : "data/workspaces/$rester_opts{workspace}";
    my $expected_uri = "$rester_opts{server}/$prefix$args{uri}";
    is_deeply $Mock_req->new_args, 
              ['HTTP::Request', $args{method}, $expected_uri],
              $expected_uri;

    for my $c (@{ $args{ua_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_ua->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method ua - @args";
    }
    is $Mock_ua->next_call, undef, 'no more ua calls';
    for my $c (@{ $args{req_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_req->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method req - @args";
    }
    is $Mock_req->next_call, undef, 'no more req calls';
    for my $c (@{ $args{resp_calls} }) {
        my ($method, @args) = @$c;
        is_deeply [$Mock_resp->next_call], 
                  [ $method, [ $Mock_ua, @args ]], 
                  "$method resp - @args";
    }
    is $Mock_resp->next_call, undef, 'no more resp calls';
}

