package PrankCall;

use strict;
use warnings;

use HTTP::Headers;
use HTTP::Request;
use IO::Socket;
use Scalar::Util qw(weaken isweak);
use Try::Tiny;
use URI;

our $VERSION = '0.004';

my $USER_AGENT = "PrankCall/$VERSION";

sub import {
  my ($class, %params) = @_;
  $USER_AGENT = $params{user_agent} if $params{user_agent};
};

sub new {
  my ($class, %params) = @_;

  my ($host, $port, $raw_host);

  if ($params{host}) {
    ($host, $port) = $params{host} =~ m{^(.*?)(?::(\d+))?$};
    $host = 'http://' . $host unless $host =~ /^http/;
    $port ||= $params{port};
    $raw_host = $host;
    $raw_host =~ s{https?://}{};
  }

  my $self = {
    blocking     => $params{blocking},
    cache_socket => $params{cache_socket},
    host         => $host,
    port         => $port,
    raw_host     => $raw_host,
    raw_string   => $params{raw_string},
    timeout      => $params{timeout},
  };

  bless $self, $class;
}

sub get {
  my ($self, %params) = @_;

  my $callback = delete $params{callback};
  my $req = $params{request_obj} || $self->_build_request(method => 'GET', %params);
  $self->_send_request($req, $callback);

  return 1;
}

sub post {
  my ($self, %params) = @_;

  my $callback = delete $params{callback};
  my $req = $params{request_obj} || $self->_build_request(method => 'POST', %params);
  $self->_send_request($req, $callback);

  return 1;
}

sub redial {
  my ($self, %params) = @_;
  die "Yo Johny, I need to know what I'm dialing!" unless $self->{_last_req};
  $self->_send_request($self->{_last_req}, delete $params{callback});
  return 1;
}

sub _build_request {
  my ($self, %params) = @_;

  my $path   = $params{path};
  my $params = $params{params};
  my $body   = $params{body};
  my $uri    = URI->new($self->{host});

  $uri->path($path);
  $uri->port($self->{port});
  $uri->query_form($params);
  my $headers = HTTP::Headers->new;

  $headers->header(
    'Content-Type' => 'application/x-www-form-urlencoded',
    'User_Agent' => $USER_AGENT,
    'Host' => $self->{raw_host},
  );

  my $req = HTTP::Request->new($params{method} => $uri, $headers);

  if ($body) {
    my $uri = URI->new('http:');
    $uri->query_form(%$body);
    my $content = $uri->query;
    $req->content($content);
    $req->content_length(length($content));
  }

  $req->protocol("HTTP/1.1");
  return $req;
}

sub _generate_http_string {
  my ($self, $req) = @_;

  my $request_path = $req->uri->path_query;
  $request_path    = "/$request_path" unless $request_path =~ m{^/};
  $request_path   .= ' '. $req->protocol if $req->protocol;

  my $http_string  = join (' ', $req->method, $request_path ) . "\n";

  if ( $req->headers ) {
    $http_string .= join ("\n", $req->headers->as_string) . "\n";
  }

  if ( $req->content ) {
    $http_string .= join ("\n", $req->content) . "\n";
  }

  return $http_string;
}

sub _send_request {
  my ($self, $req, $callback) = @_;

  my $port         = $self->{port} || $req->uri->port || '80';
  my $raw_host     = $self->{raw_host} || $req->uri->host;
  my $timeout      = $self->{timeout};
  my $blocking     = $self->{blocking} ||= 1;
  my $cache_socket = $self->{cache_socket} ||=0;

  $self->{_last_req} = $req;

  # TODO: This will probably fail when hitting a proxy
  my $http_string = $self->_generate_http_string($req);

  try {
    my $remote = $cache_socket && $self->{_socket} ?  $self->{_socket} :
      IO::Socket::INET->new(
        Proto => 'tcp',
        PeerAddr => $raw_host,
        PeerPort => $port,
        Blocking => $self->{blocking},
        $timeout ? ( Timeout => $timeout, ) : (),
      ) || die "Ah shoot Johny $!";

    $remote->autoflush(1);
    $remote->syswrite($http_string);

    if ( $cache_socket ) {
      $self->{_socket} = $remote if !$self->{_socket};
    } else {
      $remote->close;
    }

    if ($callback) {
      weaken $self;
      $callback->($self);
    }
  } catch {
    if ($callback) {
      weaken $self if isweak $self;
      $callback->($self, $_);
    }
  };
}

1;

__END__

=head1 NAME

PrankCall - call remote services and hang up without waiting for a response. A word of warning,
this module should only be used for those who are comfortable with one way communication

=head1 SYNOPSIS

    use PrankCall user_agent => 'Hangup-Howey';

    my $prank = PrankCall->new(
        host => 'somewhere.beyond.the.sea',
        port => '10827',
    );

    $prank->get(
        path => '/',
        params => { 'bobby' => 'darin' },
        callback => sub {
          my ($prank, $error) = @_;
          $prank->redial;
        }
    );

    $prank->post(path => '/', body => { 'pizza' => 'hut' });

=head1 DESCRIPTION

Sometimes you just wanna call someone and hang up without waiting for them to say anything.
PrankCall is your friend (but, oddly, also your nemesis)

=head1 METHODS

=head2 new( host => $str, [ port => $str] )

The constructor can take a number of parameters, being the usual host/port

=head2 get( path => $str, params => $hashref, [ request_obj => HTTP::Request, callback => $sub_ref ] )

Will perform a GET request, also accepts an optional HTTP::Request object and call back

=head2 post( path => $str, body => $hashref, [ request_obj => HTTP::Request, callback => sub_ref ] )

Will perform a POST request, also accepts an optional HTTP::Request object and call back

=head2 redial

Will perform a redial

=head1 AUTHOR

Logan Bell, with help from Belden Lyman

=head1 LICENSE

Copyright (c) 2013 Logan Bell and Shutterstock Inc (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself
