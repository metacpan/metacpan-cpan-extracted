#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Plack::Middleware::Debug::Ajax;

# Create a simple app
my $app = sub {
   return [ 
      200, 
      [ 'Content-Type' => 'text/plain' ],
      [ 'hello, world' ]
   ];
};

# Check that we can wrap our simple app with this middleware 
# (wrap() is from Plack::Middleware)
lives_ok {
      $app = Plack::Middleware::Debug::Ajax->wrap($app)
   }
   "No exceptions when wrapping Plack::Middleware::Debug::Ajax";

done_testing;
