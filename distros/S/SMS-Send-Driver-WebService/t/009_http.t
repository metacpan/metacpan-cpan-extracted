# -*- perl -*-
use strict;
use warnings;
#use Data::Dumper qw{Dumper};
use Test::More tests => 16;

BEGIN { use_ok( 'SMS::Send::Driver::WebService' ); }

my $live = $ENV{"PERL_HTTP_TESTS"} || 0;

SKIP: {
  skip " - export PERL_HTTP_TESTS=1 for live tests", 15 unless $live;

  my $service = SMS::Send::Driver::WebService->new(
                                                 cfg         => "",
                                                 host        => "127.0.0.1",
                                                 protocol    => "http",
                                                 port        => "80",
                                                 script_name => "/cgi-bin/hello.cgi",
                                                );

  isa_ok ($service, 'SMS::Send::Driver::WebService');
  isa_ok ($service, 'SMS::Send::Driver');
  is($service->url, "http://127.0.0.1:80/cgi-bin/hello.cgi", "url");

  {
    ok(!exists $INC{'LWP/UserAgent.pm'}, 'Ensure LWP::UserAgent is not loaded');
    my $return=$service->ua->get($service->url);
    ok(exists $INC{'LWP/UserAgent.pm'}, 'Ensure LWP::UserAgent is loaded');
    #diag(Dumper($return));
    isa_ok($return, 'HTTP::Response');
    ok($return->is_success);
    is($return->code, '200');
    is($return->content, "Hello World!\n");
  }

  {
    ok(exists $INC{'HTTP/Tiny.pm'});
    my $return=$service->uat->get($service->url);
    ok(exists $INC{'HTTP/Tiny.pm'});
    #diag(Dumper($return));
    isa_ok($return, 'HASH');
    ok($return->{'success'});
    is($return->{'status'}, '200');
    is($return->{'content'}, "Hello World!\n");
  }
}
