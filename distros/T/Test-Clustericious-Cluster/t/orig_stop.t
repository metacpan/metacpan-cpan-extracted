use strict;
use warnings;
BEGIN { $ENV{MOJO_NO_IPV6} = 1; $ENV{MOJO_NO_TLS} = 1; }
#use Carp::Always::Dump;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
use IO::Socket::INET;

skip_all 'cannot turn off Mojo IPv6'
  if IO::Socket::INET->isa('IO::Socket::IP');

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( MyApp MyApp MyApp ));
my $t = $cluster->t;
my @url = @{ $cluster->urls };

subtest 'servers start as up' => sub {
  $t->get_ok("$url[0]/foo")
    ->status_is(200);
  $t->get_ok("$url[1]/foo")
    ->status_is(200);
  $t->get_ok("$url[2]/foo")
    ->status_is(200);
};

subtest 'stop middle server' => sub {
  $cluster->stop_ok(1);

  subtest 'left' => sub {
    $t->get_ok("$url[0]/foo")
      ->status_is(200);
  };

  subtest 'middle' => sub {
    my $tx = $t->ua->get("$url[1]/foo");
    ok !$tx->success, "GET $url[1]/foo [connection refused]";
    my $error = $tx->error->{message};
    my $code  = $tx->error->{code};
    ok $error, "error = $error";
    $code//='';
    ok !$code, "code  = $code";
  };
  
  subtest 'right' => sub {
    $t->get_ok("$url[2]/foo")
      ->status_is(200);
  };
  
  subtest 'middle with new ua' => sub {
    
    my $ua = $cluster->create_ua;
    
    my $tx = $ua->get("$url[1]/foo");
    ok(!$tx->success, "GET $url[1]/foo [connection refused]") || diag $tx->res->to_string;
    
    my $error = eval { $tx->error->{message} };
    my $code  = eval { $tx->error->{code} };
    $error//='';
    ok $error, "error = $error";
    $code//='';
    ok !$code, "code  = $code";
  };
  
  subtest 'is_stopped / isnt_stopped' => sub {
    $cluster->isnt_stopped(0);
    $cluster->is_stopped(1);
    $cluster->isnt_stopped(2);
  };
};

subtest 'restart middle server' => sub {
  $cluster->start_ok(1);

  $t->get_ok("$url[0]/foo")
    ->status_is(200);
  $t->get_ok("$url[1]/foo")
    ->status_is(200);
  $t->get_ok("$url[2]/foo")
    ->status_is(200);
    
  subtest 'with create_ua' => sub {
    my $ua = $cluster->create_ua;
    
    my $tx = $ua->get("$url[1]/foo");
    
    ok $tx->success, "GET $url[1]/foo SUCCESS";
    #note $tx->res->to_string;
    is $tx->res->code, 200, 'code == 200';
    is $tx->res->body, 'bar1', 'body = bar1';
  };
};

subtest 'stop end server using relative url' => sub {

  subtest 'get before stop' => sub {
    $t->get_ok('/foo')
      ->status_is(200)
      ->content_is('bar2');
    ok $t->ua->server->app;
  };

  $cluster->stop_ok(2);

  subtest 'get after stop' => sub {
    ok !$t->ua->server->app;

    # we can test this but it times out
    # and it issues warnings that are 
    # messy, so just heck that the app
    # object above is bad.
    #my $ua = $t->ua;
    #my $tx = $ua->get("/foo");
    #ok !$tx->success, 'not successful';
  };
  
  $cluster->start_ok(2);

  subtest 'get before stop' => sub {
    $t->get_ok('/foo')
      ->status_is(200)
      ->content_is('bar2');
    ok $t->ua->server->app;
  };
};

done_testing;

__DATA__

@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use 5.010001;
use Mojo::Base qw( Mojolicious );

sub startup
{
  my($self) = @_;
  state $index = 0;
  $self->{index} = $index++;
  $self->routes->get('/foo' => sub { shift->render(text => "bar" . $self->{index}) });
}

1;
