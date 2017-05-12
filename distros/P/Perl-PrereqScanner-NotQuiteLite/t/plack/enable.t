use strict;
use warnings;
use Test::More;
use t::Util;

test('enable', <<'END', {'Plack::Builder' => 0, 'Plack::Middleware::Foo' => 0});
use Plack::Builder;
builder {
  enable 'Foo';
};
END

test('enable plus', <<'END', {'Plack::Builder' => 0, 'Foo' => 0});
use Plack::Builder;
builder {
  enable '+Foo';
};
END

done_testing;
