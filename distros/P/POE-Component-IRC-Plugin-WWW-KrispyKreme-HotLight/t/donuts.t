use strict;
use warnings;

use Test::More;
use POE::Component::IRC::Plugin::WWW::KrispyKreme::HotLight;

my $class = 'POE::Component::IRC::Plugin::WWW::KrispyKreme::HotLight';

can_ok($class,qw(new _donuts));

my $donut = new_ok($class => [geo => [34.01, -118.50]]);

done_testing;
