use strict;

use Test::More;
use Perlbal::Plugin::Expires;

my $delta = Perlbal::Plugin::Expires::_expires_to_sec('10 days');
is $delta, 10*24*60*60;

$delta = Perlbal::Plugin::Expires::_expires_to_sec('3 years 5 days');
is $delta, 3*365*24*60*60 + 5*24*60*60;

$delta = Perlbal::Plugin::Expires::_expires_to_sec('1 day 2 hours 3 minutes');
is $delta, 1*24*60*60 + 2*60*60 + 3*60;

done_testing;
