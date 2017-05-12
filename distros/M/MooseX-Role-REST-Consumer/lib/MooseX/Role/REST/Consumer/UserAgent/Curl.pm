use strict;
use warnings;

package MooseX::Role::REST::Consumer::UserAgent::Curl;

use Moose;
use HTTP::Headers;
extends 'WWW::Curl::UserAgent';

sub agent {
  shift->user_agent_string(@_);
}

#FIXME: version of libcurl that we have has a bug in subsecond timeouts
has '+connect_timeout' => ( default => sub { 1000 } );

sub default_headers { HTTP::Headers->new };
sub use_eval {};

sub timeout {
  my ($self) = shift;
  if(@_) {
    my $timeout = $_[0] * 1000;
    $self->SUPER::timeout($timeout);
  } else {
    return $self->SUPER::timeout;
  }
};

__PACKAGE__->meta->make_immutable;
1;
