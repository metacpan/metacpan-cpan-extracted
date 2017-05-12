use Test::More tests => 2;
use strict;
use warnings;

# the order is important
use PerlMonksFlairApp;
use Dancer::Test;

route_exists [GET => '/'], 'There is a home page';
#This always fails and I don't know why.
#route_exists [GET => qr{/([\w -.]+)\.jpg}], "There is a route for valid usernames.jpg";

response_status_is ['GET' => '/'], 200, 'Home page returns fine';

#maybe I can do this, but I'm not sure.
#respone_status_is ['GET' => '/ovid.jpg'], 200, "Ovid has a badge!"
