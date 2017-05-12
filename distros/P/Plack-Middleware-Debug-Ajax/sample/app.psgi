#!/usr/bin/env perl

use strict;
use warnings;

use lib './lib';

use Plack::Builder;
use Plack::Middleware::Debug::Ajax;

# Main app
my @data = <DATA>;
my $app = sub {
   return [
      200,
      [ 'Content-Type' => 'text/html' ],
      [ @data ]
   ];
};

# Return correct JSON
my $success = sub {
   return [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ '{ "msg": "hello"}' ]
   ];
};

# Return invalid json
my $failure = sub {
   return [
      200,
      [ 'Content-Type' => 'application/json' ],
      [ '{ bad json: "hello"}' ]
   ];
};

# 404 page
my $not_found = sub {
   return [
      404,
      [ 'Content-Type' => 'text/plain' ],
      [ 'No page found' ]
   ];
};

# Enable our middleware
$app = builder {
         enable 'Debug', panels =>
               [ 
                  qw(Parameters Memory),
                  [ 'Ajax',
                     log_limit => 100,
                  ]
               ];

         mount "/"        => $app;
         mount "/success" => $success;
         mount "/failure" => $failure;
         mount "/404"     => $not_found;
};

__DATA__
<!DOCTYPE HTML>
<html>
   <head>
      <title>Plack::Middleware::Debug::Ajax Example</title>
      <script src="http://code.jquery.com/jquery-1.8.3.js"></script>
   </head>
   <body>
      <p>Welcome to the demo of Plack::Middleware::Debug::Ajax. This plugin
      logs ajax requests, responses and failures as they happen, so long as
      they are made through jQuery.</p>
      <p>Click the following button to fire off all of the below requests at
      once:</p>
      <button id="all">Fire off all of below requests</button>

      <p>Click the following buttons to fire off individual ajax requests:</p>
      <ul>
         <li>
            <button data-url="/failure" data-method="POST">
               POST request that will fail
            </button>
         </li>
         <li>
            <button data-url="/success" data-method="POST">
               POST request that will succeed
            </button>
         </li>
         <li> <button data-url="/failure" data-method="GET">
               GET request that will fail
            </button>
         </li>
         <li>
            <button data-url="/success" data-method="GET">
               GET request that will succeed
            </button>
         </li>
         <li>
            <button data-url="/404" data-method="POST">
               POST Request to bad url
            </button>
         </li>
         <li>
            <button data-url="/" data-method="POST">
               POST Request to get source of this page
            </button>
         </li>
      </ul>

      <div id="msg" style="display:none">
         <p style="font-size:2em">See the results in the Ajax log on the right &rarr;</p>
      </div>

      <script>
      $(function() {
         // Fire off a bunch
         $('#all').click(function() {
            $('ul button').trigger('click');
         });

         // Individual
         $('ul button').click(function() {
            $.ajax({
               type: $(this).attr("data-method"),
               url:  $(this).attr("data-url"),
               data: {
                  msg: "This is the message sent in the request",
               }
            });
         });

         // Show message on first button click
         $('button').one('click', function() {
            $('#msg').show(400);
         });
      });
      </script>
   </body>
</html>
