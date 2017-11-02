# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package t::Mock::Agent;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 t::Mock::Agent

Mock LWP::UserAgent calls with mocked HTTP::Response-objects

=cut

use LWP::UserAgent;

no warnings 'void';
*originalSub;
use warnings 'void';
my $response;

sub setResponse($code, $msg, $header, $content) {
  $response = HTTP::Response->new( $code, $msg, $header, $content )
}

sub beginMockingWithResponse($code, $msg, $header, $content) {
  setResponse($code, $msg, $header, $content);
  beginMocking();
}

sub beginMocking {
  *originalSub = *LWP::UserAgent::request;

  no warnings 'redefine';
  *LWP::UserAgent::request = sub {
      my $class = shift;

      return $response if defined $response;
      die "No response";
  };
  use warnings 'redefine';
}

sub stopMocking {
  *LWP::UserAgent::request = *originalSub if *originalSub;
}

1;
