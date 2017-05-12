#! /usr/bin/perl
# -*- perl -*-
# vim: filetype=perl sw=2 ts=2 expandtab

# Contributed by Yuri Karaban.  Thank you!

use strict;
use warnings;

use Test::More tests => 9;

$SIG{PIPE} = 'IGNORE';

use Socket;

use POE;
use POE::Session;
use POE::Component::Server::TCP;
use POE::Component::Client::HTTP;
use POE::Filter::HTTPD;
use HTTP::Request;
use HTTP::Request::Common qw(GET PUT);

use HTTP::Response;

# We need some control over proxying here.
BEGIN {
  delete $ENV{HTTP_PROXY};
  for (qw /HTTP_PROXY http_proxy NO_PROXY no_proxy/) {
    delete $ENV{$_};
  }
}

POE::Session->create(
   inline_states => {
    _child => sub { undef },
    _stop => sub { undef },

    _start => sub {
      my $kernel = $_[KERNEL];
      $kernel->alias_set('main');

      spawn_http('proxy1');
      spawn_http('proxy2');
      spawn_http('host');
      spawn_rproxy();
    },
    set_port => sub {
      my ($kernel, $heap, $name, $port) = @_[KERNEL, HEAP, ARG0, ARG1];

      $heap->{$name} = "http://127.0.0.1:$port/";

      if (++ $_[HEAP]->{ready_cnt} == 4) {
        $_[KERNEL]->yield('begin_tests');
      }
    },
    begin_tests => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      POE::Component::Client::HTTP->spawn(Alias => 'DefProxy', Proxy => $heap->{proxy1});
      POE::Component::Client::HTTP->spawn(Alias => 'NoProxy', FollowRedirects => 3);

      # Test is default proxy working
      $kernel->post(DefProxy => request => test1_resp => GET $heap->{host});
    },
    test1_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      ok($resp->is_success && $resp->content eq 'proxy1');

      # Test is default proxy override working
      $kernel->post(DefProxy => request => test2_resp => (GET $heap->{host}), undef, undef, $heap->{proxy2});
    },
    test2_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      ok($resp->is_success && $resp->content eq 'proxy2');

      # Test per request proxy setting (override with no default proxy)
      $kernel->post(NoProxy => request => test3_resp => (GET $heap->{host}), undef, undef, $heap->{proxy1});
    },
    test3_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      ok($resp->is_success && $resp->content eq 'proxy1');

      # Test when no proxy set at all
      $kernel->post(NoProxy => request => test4_resp => GET $heap->{host});
    },
    test4_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      ok($resp->is_success && $resp->content eq 'host');

      # Test is default proxy works for POST
      $heap->{cookie} = rand;
      my $req = HTTP::Request->new(POST => $heap->{host}, ['Content-Length' => length($heap->{cookie})], $heap->{cookie});
      $kernel->post(DefProxy => request => test5_resp => $req);
    },
    test5_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      if ($resp->is_success) {
        my ($name, $content) = split(':', $resp->content);
        ok($name eq  'proxy1' && $content eq $heap->{cookie});
      } else {
        fail();
      }

      # Test is default proxy override works for POST
      $heap->{cookie} = rand;
      my $req = HTTP::Request->new(POST => $heap->{host}, ['Content-Length' => length($heap->{cookie})], $heap->{cookie});

      $kernel->post(DefProxy => request => test6_resp => $req, undef, undef, $heap->{proxy2});
    },
    test6_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      if ($resp->is_success) {
        my ($name, $content) = split(':', $resp->content);
        ok($name eq  'proxy2' && $content eq $heap->{cookie});
      } else {
        fail();
      }

      # Test is per request proxy  works for POST
      $heap->{cookie} = rand;
      my $req = HTTP::Request->new(POST => $heap->{host}, ['Content-Length' => length($heap->{cookie})], $heap->{cookie});

      $kernel->post(NoProxy => request => test7_resp => $req, undef, undef, $heap->{proxy1});
    },
    test7_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      if ($resp->is_success) {
        my ($name, $content) = split(':', $resp->content);
        ok($name eq  'proxy1' && $content eq $heap->{cookie});
      } else {
        fail();
      }

      # Test is no for POST
      $heap->{cookie} = rand;
      my $req = HTTP::Request->new(POST => $heap->{host}, ['Content-Length' => length($heap->{cookie})], $heap->{cookie});

      $kernel->post(NoProxy => request => test8_resp => $req);
    },
    test8_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      if ($resp->is_success) {
        my ($name, $content) = split(':', $resp->content);
        ok($name eq  'host' && $content eq $heap->{cookie});
      } else {
        fail();
      }

      $kernel->post(NoProxy => request => test9_resp => (GET 'http://redirect.me/'),
        undef, undef, $heap->{rproxy});
    },
    test9_resp => sub {
      my ($kernel, $heap, $resp_pack) = @_[KERNEL, HEAP, ARG1];
      my $resp = $resp_pack->[0];

      ok($resp->is_success && $resp->content eq 'rproxy');

      $kernel->post(proxy1 => 'shutdown');
      $kernel->post(proxy2 => 'shutdown');
      $kernel->post(rproxy => 'shutdown');
      $kernel->post(host => 'shutdown');

      $kernel->post(DefProxy => 'shutdown');
      $kernel->post(NoProxy => 'shutdown');
    }
  },
  heap => {
    ready_cnt => 0
  }
);

POE::Kernel->run();
exit 0;

sub spawn_http {
  my $name = shift;

  POE::Component::Server::TCP->new(
    Alias        => $name,
    Address      => '127.0.0.1',
    Port         => 0,
    ClientFilter => 'POE::Filter::HTTPD',

    ClientInput => sub { unshift @_, $name; &handle_request },
    Started => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];
      my $port = (sockaddr_in($heap->{listener}->getsockname))[0];

      $kernel->post('main', 'set_port', $name, $port);
    }
  );
}

sub spawn_rproxy  {
  POE::Component::Server::TCP->new(
    Alias        => 'rproxy',
    Address      => '127.0.0.1',
    Port         => 0,
    ClientFilter => 'POE::Filter::HTTPD',

    ClientInput => \&handle_rproxy_request,
    Started => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];
      my $port = (sockaddr_in($heap->{listener}->getsockname))[0];

      $kernel->post('main', 'set_port', 'rproxy', $port);
    }
  );
}

sub handle_request {
  my $name = shift;
  my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

  if ( $request->isa("HTTP::Response") ) {
    $heap->{client}->put($request);
    $kernel->yield("shutdown");
    return;
  }

  my ($body, $host);
  if (
    (
      (
        $name =~ /^proxy/ &&
       defined($host = $kernel->alias_resolve('main')->get_heap->{host}) &&
        $request->uri->canonical ne $host
      )
      ||
      (
        $name !~ /^proxy/ &&
        $request->uri->canonical ne '/'
      )
    )
  ) {
    $body = 'url does not match';
  } else {
    $body = $name;
  }

  if ($request->method eq "POST") {
    # passthrough cookie
    $body .= ':' . $request->content;
  }

  my $r = HTTP::Response->new(
    200,
    'OK',
    ['Connection' => 'Close', 'Content-Type' => 'text/plain'],
    $body
  );

  $heap->{client}->put($r) if defined $heap->{client};

  $kernel->yield("shutdown");
}

sub handle_rproxy_request {
  my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

  if ($request->isa("HTTP::Response")) {
    $heap->{client}->put($request);
    $kernel->yield("shutdown");
    return;
  }

  my $host = $kernel->alias_resolve('main')->get_heap->{host};
  my $r;

  if ($request->uri->canonical eq 'http://redirect.me/') {
    $r = HTTP::Response->new
      (302,
       'Moved',
       ['Connection' => 'Close',
        'Content-Type' => 'text/plain',
        'Location' => $host
       ]);
  } else {
    $r = HTTP::Response->new
      (
       200,
       'OK',
       ['Connection' => 'Close', 'Content-Type' => 'text/plain'],
       $request->uri->canonical eq $host ? 'rproxy' : 'fail'
      );
  }
  $heap->{client}->put($r) if defined $heap->{client};
  $kernel->yield("shutdown");
}
