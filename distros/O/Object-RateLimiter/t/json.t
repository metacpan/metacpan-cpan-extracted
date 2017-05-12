BEGIN {
  require Test::More;
  unless (eval {; require JSON::MaybeXS; 1 } && !$@) {
    Test::More::plan(skip_all => 'these tests require JSON::MaybeXS')
  }
}

use Test::More;
use strict; use warnings;

use Object::RateLimiter;
use JSON::MaybeXS;

my $js = JSON::MaybeXS->new(convert_blessed => 1);

my $ctrl = Object::RateLimiter->new(
  events  => 3,
  seconds => 1200,
);

$ctrl->delay for 1 .. 3;
my $delay = $ctrl->delay;
cmp_ok $delay, '>', 0, 'delayed before store ok';

my $stored = $js->encode($ctrl);
my $recreated = Object::RateLimiter->new( $js->decode($stored) );
cmp_ok $recreated->events, '==', 3, 'events after store/new ok';
cmp_ok $recreated->seconds, '==', 1200, 'seconds after store/new ok';
cmp_ok $recreated->delay, '>', 0, 'delayed after store/new ok';

done_testing
