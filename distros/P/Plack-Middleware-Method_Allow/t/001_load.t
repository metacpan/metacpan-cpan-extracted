use strict;
use warnings;
use Test::More tests => 23;
BEGIN { use_ok('Plack::Middleware::Method_Allow') };

my $obj = Plack::Middleware::Method_Allow->new;
can_ok($obj, 'call');
can_ok($obj, 'allow');
isa_ok($obj, 'Plack::Middleware::Method_Allow');
isa_ok($obj, 'Plack::Middleware');
isa_ok($obj->allow, 'ARRAY', 'allow');
is(scalar(@{$obj->allow}), 0, 'allow');
isa_ok($obj->allow(['foo']), 'ARRAY', 'allow');
is(scalar(@{$obj->allow}), 1, 'allow');

foreach my $ref ('foo', 0, '', {}, (\my $x), (bless []), (bless {})) {
  local $@;
  eval{$obj->allow($ref)};
  my $error = $@;
  ok($error, 'allow dies with bad data');
  like($error, qr/Syntax/, 'allow with '. ref($ref));
}
