use strict;
use warnings;
use URI;
use REST::Client;
use Test::More;

require_ok 'REST::Cot::Fragment';

my $obj = bless({
    parent => undef,
    client => REST::Client->new({host => 'http://example.com'}),
    path => sub { '' }
}, 'REST::Cot::Fragment');

isa_ok $obj, 'REST::Cot::Fragment'
  or diag $obj;

can_ok $obj, $_ for qw[GET PUT PATCH POST DELETE OPTIONS HEAD];

isa_ok $obj->foo, 'REST::Cot::Fragment';


is $obj->foo->{path}->(), '/foo';

is $obj->foo->bar->{path}->(), '/foo/bar';

is $obj->stuff(qw[a b])->{path}->(), '/stuff/a/b';

is $obj->stuff('v0.1')->{path}->(), '/stuff/v0.1';

isa_ok $obj->foo->{uri}->(), 'URI';

isa_ok $obj->foo({ 'a' => 'b', 'c' => 'd' })->{uri}->(), 'URI';

like $obj->foo({ 'a' => 'b', 'c' => 'd' }, 'bar'), qr|/foo/bar\?|;

my $u = $obj->foo({'a' => 'b'})->bar({'c' => 'd'})->{uri}->();
my $q = {$u->query_form};

is_deeply($q, {'a' => 'b', 'c' => 'd'});

done_testing();
