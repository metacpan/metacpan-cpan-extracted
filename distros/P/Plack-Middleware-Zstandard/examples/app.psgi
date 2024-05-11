#!/usr/bin/env perl

use strict;
use warnings;
use Plack::Builder;

my $app = sub {
  return [
    200,
    [ 'Content-Type' => 'text/plain' ],
    [ "Hello World!\n" ],
  ];
};

builder {
  enable 'Zstandard';
  $app;
};
