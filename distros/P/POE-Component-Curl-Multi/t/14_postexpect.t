#! /usr/bin/perl
# -*- perl -*-
# vim: ts=2 sw=2 filetype=perl expandtab

use strict;
use warnings;

use Test::More tests => 3;

use POE;
use POE::Component::Curl::Multi;
use POE::Component::Server::TCP;
use HTTP::Request::Common qw[POST];
use Socket;

my $json = '{"author":["Chris Williams"],"release_status":"stable","prereqs":{"develop":{"requires":{"Pod::Coverage::TrustPod":"0","Test::Pod":"1.41","Test::Pod::Coverage":"1.08"}},"runtime":{"requires":{"HTTP::Status":"5.811","POE":"1.312","HTTP::Request::Common":"5.811","URI":"1.37","HTTP::Headers":"5.810","POE::Component::Server::TCP":"0","HTTP::Request":"5.811","WWW::Curl":"4.15","HTTP::Response":"5.813"}},"configure":{"requires":{"ExtUtils::MakeMaker":"6.30"}},"test":{"requires":{"IO::Handle":"0","Test::More":"0.96","IPC::Open3":"0","File::Spec":"0"}}},"generated_by":"Dist::Zilla version 5.013, CPAN::Meta::Converter version 2.140640","dynamic_config":0,"name":"POE-Component-Curl-Multi","meta-spec":{"url":"http://search.cpan.org/perldoc?CPAN::Meta::Spec","version":"2"},"resources":{"homepage":"https://github.com/bingos/poe-component-curl-multi","repository":{"url":"https://github.com/bingos/poe-component-curl-multi.git","type":"git","web":"https://github.com/bingos/poe-component-curl-multi"}},"license":["perl_5"],"version":"0.08","abstract":"a fast HTTP POE component"}';

POE::Component::Curl::Multi->spawn(
 Alias => 'ua',
 Timeout => 2,
 Agent => 'OleBiscuitBarrel/1.0',
);

# We are testing against a localhost server.
# Don't proxy, because localhost takes on new meaning.
BEGIN {
  delete $ENV{HTTP_PROXY};
  delete $ENV{http_proxy};
}

POE::Session->create(
   inline_states => {
    _start => sub {
      my ($kernel) = $_[KERNEL];

      $kernel->alias_set('Main');

      # Spawn discard TCP server
      POE::Component::Server::TCP->new (
        Alias       => 'Discard',
        Address     => '127.0.0.1',
        Port        => 0,
        ClientFilter => 'POE::Filter::HTTPD',
        ClientInput => sub {
            my $input = $_[ARG0];
            isa_ok( $input, 'HTTP::Request', 'We got a HTTP::Request' );
            my $headers = $input->headers_as_string;
            unlike( $headers, qr/Expect:/s, 'There is not an Expect header' );
        }, # discard
        Started     => sub {
          my ($kernel, $heap) = @_[KERNEL, HEAP];
          my $port = (sockaddr_in($heap->{listener}->getsockname))[0];
          $kernel->post('Main', 'set_port', $port);
        }
      );
    },
    set_port => sub {
      my ($kernel, $port) = @_[KERNEL, ARG0];

      my $url = "http://127.0.0.1:$port/";
      my $req = POST $url,
        Content_Type => 'application/json',
        Accept       => 'application/json',
        Content      => $json;

      $kernel->post(ua => request => response => $req);
      $kernel->delay(no_response => 10);
    },
    response => sub {
      my ($kernel, $rspp) = @_[KERNEL, ARG1];
      my $rsp = $rspp->[0];

      $kernel->delay('no_response'); # Clear timer
      ok($rsp->code == 408, "received error " . $rsp->code . " (wanted 408)");
      $kernel->post(Discard => 'shutdown');
      $kernel->post(ua => 'shutdown');
    },
    no_response => sub {
      my $kernel = $_[KERNEL];
      fail("didn't receive error 408");
      $kernel->post(Discard => 'shutdown');
      $kernel->post(ua => 'shutdown');
    }
  }
);

POE::Kernel->run;
exit;
