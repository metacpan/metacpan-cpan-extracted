#! /usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use Test::Deep;
use Test::Easy qw(resub wiretap);

use_ok 'MooseX::Role::REST::Consumer';
subtest "Standard GET request" => sub {
  plan tests => 5;

  {
    package FooTestParams;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions/:{id}/:param/:last_param',
      query_params_mapping => { query_id => 'id' }
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get';
  my $consumer_new_wt = wiretap 'REST::Consumer::new';

  my $obj;
  lives_ok { $obj = FooTestParams->new } "Creating a class that implments MX::R::REST::Consumer lives!";

  subtest "Some basic tests to make sure that parameter replacing is working as expected" => sub {
    plan tests => 11;

    is $obj->request_path(
        resource_path => '/:id/',
        route_params => { id => 123 }
    ), '/123/';

    is $obj->request_path(
      resource_path => '/:id',
      route_params => { id => 123 }
    ), '/123';

    is $obj->request_path(
      resource_path => '/:{id}/',
      route_params  => { id => 123 },
    ),'/123/';

    is $obj->request_path(
      resource_path => '/:{id}',
      route_params  => { id => 123 }
    ), '/123';

    is $obj->request_path(
      resource_path => '/aaa/:{id}.json',
      route_params  => { id => 123 }
    ), '/aaa/123.json';

    is $obj->request_path(
      resource_path => '/aaa/:{id.id}.json',
      route_params  => { "id.id" => 123 }
    ), '/aaa/123.json';

    is $obj->request_path(
      resource_path => '/:id/:id_new/',
      route_params  => { id => 123, id_new => 321 }
    ), '/123/321/';

    is $obj->request_path(
      resource_path => '/:id:id_new/',
      route_params  => { id => 123, id_new => 321 }
    ), '/123321/';

    is $obj->request_path(
      resource_path => '/:id:id_new',
      route_params => { id => 123, id_new => 321 }
    ), '/123321';

    throws_ok {
      $obj->request_path(
        resource_path => '/:id/:id_new/',
        route_params  => { id => 123 }
      ) 
    } qr/Found parameter id_new/, 'Die if parameter is not found';

    is $obj->request_path(
        resource_path => '/:id:id_new/',
        route_params  => { id => ":id_new", id_new => ":id" }
      ), '/%3Aid_new%3Aid/', 'make sure we do not subsitute in values';
  };

  lives_ok {
    $obj->get(
      params => {
        query_id => 1
      },
      route_params => {
        id => 123,
        param => 'param_value',
        last_param => 'last/param/value',
      },
      content => 'content'
    ) 
  } "Calling get returns something";

  cmp_deeply($consumer_new_wt->named_method_args, [{
    timeout => 1,
    host => 'session.dev.shuttercorp.net'
  }]);

  cmp_deeply $consumer_get_rs->named_method_args,[
    {
      params => {
        id => 1
      },
      content_type => 'application/json',
      headers => undef,
      content => 'content',
      path => '/sessions/123/param_value/last%2Fparam%2Fvalue'
    }
  ];

};

subtest "GET/POST request" => sub {
  plan tests => 9;

  {
    package Foo::Test;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
      timeout => 0.5,
    };
  }

  my $consumer_new_wt = wiretap 'REST::Consumer::new';
  my $consumer_get_rs = resub 'REST::Consumer::get';
  my $consumer_post_rs = resub 'REST::Consumer::post';

  my ($obj, $get_req, $post_req);

  lives_ok { $obj = Foo::Test->new } "Creating a class that implments MX::R::REST::Consumer lives!";
  lives_ok { $get_req = $obj->get(path => 1) } "Calling get returns something";
  lives_ok { $post_req = $obj->post(path => 1, content => { content => 'POST!' } ) }
      "Calling post returns something";

  cmp_deeply($consumer_new_wt->named_method_args, [{
    timeout => 0.5,
    'host' => 'session.dev.shuttercorp.net'
   }]);

  cmp_deeply $consumer_get_rs->named_method_args, [
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => undef,
      path => '/sessions/1'
    }
  ];

  cmp_deeply $consumer_post_rs->named_method_args, [
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => {
        content => 'POST!'
      },
      path => '/sessions/1'
    }
  ];


  #Call get and post again and make sure we create only one REST::Consumer after all
  lives_ok { $obj->get(path => 1) } "Calling get returns something";
  lives_ok { $obj->post(path => 1, content => { content => 'POST!' } ) }
      "Calling post returns something";

  cmp_deeply($consumer_new_wt->named_method_args, [{
    timeout => 0.5,
    host => 'session.dev.shuttercorp.net'
   }], 'Make sure that we create only one REST::Consumer instance');
};

subtest "Testing a service exception" => sub {
  plan tests => 5;

  {
    package Foo::Test::Error;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
      timeout => 0.5,
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get' => sub { die "error"; };

  my ($obj, $get_req);

  lives_ok { $obj = Foo::Test::Error->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";
  lives_ok { $get_req = $obj->get(path => 1) } "Calling get returns something";

  ok !$get_req->is_success, "the get was not successful";
  like $get_req->error_message, qr/error/;

  cmp_deeply $consumer_get_rs->named_method_args, [
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => undef,
      path => '/sessions/1'
    }
  ];

};

subtest "We should be able to set custom headers" => sub {
  plan tests => 3;
  {
    package CustomHeadersTest;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get', sub {};
  my ($obj, $get_req);

  lives_ok { $obj = CustomHeadersTest->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";

  lives_ok {
    $get_req = $obj->get(path => 1, headers => {
      'X-Foo-Bar' => 'Random header 1',
      'X-Baz-Jazz' => 'Random header 2'
     });
  } "Calling get returns something";

  cmp_deeply($consumer_get_rs->named_method_args, [{
    path => '/sessions/1',
    headers => bag(
      'X-Baz-Jazz',
      'Random header 2',
      'X-Foo-Bar',
      'Random header 1'
    ),
    content_type => 'application/json',
    params => {},
    content => undef
   }], "we called the service with custom headers");
};

subtest "We should be able to use custom user agent" => sub {
  plan tests => 4;
  {
    package CustomUserAgentTest;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
      useragent_class => 'MooseX::Role::REST::Consumer::UserAgent::Curl',
    };
  }

  my $consumer_new_wt = wiretap 'REST::Consumer::new';
  my $consumer_get_rs = resub 'REST::Consumer::get', sub {};
  my ($obj, $get_req);

  lives_ok { $obj = CustomUserAgentTest->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";

  lives_ok {
    $get_req = $obj->get(path => 1);
  } "Calling get returns something";

  cmp_deeply($consumer_new_wt->named_method_args, [{
    ua => isa('MooseX::Role::REST::Consumer::UserAgent::Curl'),
    timeout => 1,
    host => 'session.dev.shuttercorp.net'
   }], "we called the service");

  cmp_deeply($consumer_get_rs->named_method_args, [{
    path => '/sessions/1',
    headers => undef,
    content_type => 'application/json',
    params => {},
    content => undef
   }], "we called the service");
};

subtest "Testing a service exception with timeout_retry set" => sub {
  plan tests => 4;

  {
    package Foo::Test::ErrorWithTimeout;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
      timeout => 0.5,
      retry => 2,
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get', sub { die "had a read timeout"; };

  my ($obj, $get_req);

  lives_ok { $obj = Foo::Test::ErrorWithTimeout->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";

  lives_ok { $get_req = $obj->get(path => 1) } "Calling get returns something";

  ok !$get_req->is_success, "the get was not successful";

  cmp_deeply $consumer_get_rs->named_method_args, [
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => undef,
      path => '/sessions/1'
    },
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => undef,
      path => '/sessions/1'
    },
    {
      params => {},
      content_type => 'application/json',
      headers => undef,
      content => undef,
      path => '/sessions/1'
    }
  ];

};

subtest "We should be able to set custom headers" => sub {
  plan tests => 3;
  {
    package CustomHeadersTest;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'session.dev.shuttercorp.net',
      resource_path => '/sessions',
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get', sub {};
  my ($obj, $get_req);

  lives_ok { $obj = CustomHeadersTest->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";

  lives_ok {
    $get_req = $obj->get(
        path => 1,
        headers => {
          'X-Foo-Bar' => 'Random header 1',
          'X-Baz-Jazz' => 'Random header 2'
        }, 
        access_token => "meshuggaas-saccated",        
    );
  } "Calling get returns something";

  cmp_deeply($consumer_get_rs->named_method_args, [{
    path => '/sessions/1',
    headers => bag(
      'X-Baz-Jazz',
      'Random header 2',
      'X-Foo-Bar',
      'Random header 1',
      'Authorization',
      'Bearer meshuggaas-saccated',
    ),
    content_type => 'application/json',
    params => {},
    content => undef
   }], "we called the service with custom headers");
};

subtest "overriding a timeout/host" => sub {
  plan tests => 8;
  {
    package OverrideTimeout;
    use Moose;
    with 'MooseX::Role::REST::Consumer' => {
      service_host => 'http://foo.com',
      resource_path => '/bar',
      timeout => '20',
    };
  }

  my $consumer_get_rs = resub 'REST::Consumer::get';
  my $consumer_timout_wt = wiretap 'REST::Consumer::timeout';
  my $consumer_host_wt = wiretap 'REST::Consumer::host';

  my ($obj, $get_req);
  lives_ok { $obj = OverrideTimeout->new }
      "Creating a class that implments MX::R::REST::Consumer lives!";

  lives_ok {
    $get_req = $obj->get(timeout => 1, host => 'http://bar.com');
  } "Calling get returns something";

  cmp_deeply($consumer_get_rs->named_method_args, [{
    path => '/bar',
    headers => ignore(),
    content_type => 'application/json',
    params => {},
    content => undef
   }], "we called the service with custom headers");

  is $obj->consumer->timeout, 20;
  is $obj->consumer->host, 'http://foo.com';
  is($consumer_timout_wt->method_args->[1][0],1);
  is($consumer_host_wt->method_args->[0][0],'http://bar.com');
  is($consumer_host_wt->method_args->[1][0],'http://foo.com');
};
