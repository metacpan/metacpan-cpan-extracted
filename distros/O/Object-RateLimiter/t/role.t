use strict; use warnings;

{ package My::Obj;
  use Role::Tiny::With;
  with 'Role::Object::RateLimiter';
  sub new { bless +{}, shift }
}

use Test::More;

my $obj = My::Obj->new;
isa_ok $obj->delayed(events => 3, seconds => 1200), 'Object::RateLimiter',
  '->delayed returns Object::RateLimiter';

ok !$obj->delayed, 'delay 1 (0) ok';
ok !$obj->delayed, 'delay 2 (0) ok';
ok !$obj->delayed, 'delay 3 (0) ok';
cmp_ok $obj->delayed, '<=', 1200, 'delay 4 (<=1200) ok';

$obj->clear_delayed;
ok !$obj->delayed, 'delay cleared ok';

isa_ok $obj->get_rate_limiter, 'Object::RateLimiter',
  'get_rate_limiter returned obj';
ok $obj->get_rate_limiter->seconds == 1200, 'obj appears to be correct';

eval {; My::Obj->new->delayed };
like $@, qr/delayed/, 'delayed without configured limiter dies';

done_testing
