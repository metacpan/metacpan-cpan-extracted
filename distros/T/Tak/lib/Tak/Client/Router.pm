package Tak::Client::Router;

use Moo;

extends 'Tak::Client';

sub ensure {
  shift->do(meta => ensure => @_);
}

1;
