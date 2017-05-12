# Simple test to check if all the included modules load properly

# luismunoz@cpan.org
# $Id: 00-load.t,v 1.2 2002/10/23 04:43:58 lem Exp $

use Test::More tests => 6;

for my $mod (qw(Net::DNS::Method 
		Net::DNS::Method::Hash 
		Net::DNS::Method::Pool 
		Net::DNS::Method::Regexp
		Net::DNS::Method::Status 
		Net::DNS::Method::Constant ))
{
    eval "use $mod;";

    ok(!$@, "use $mod");
}

