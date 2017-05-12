#!/usr/bin/perl

use Plack::Builder;
builder {
   enable 'Plack::Middleware::AutoRefresh';

   sub {
       [
           200,
           [ 'content-type' => 'text/html' ],
           [ '<html><head></head><body>hello world</body></html>' ]
       ]
   }
};
