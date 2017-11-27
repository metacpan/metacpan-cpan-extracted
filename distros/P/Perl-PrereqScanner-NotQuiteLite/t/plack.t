use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
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

test('enable_if', <<'END', {'Plack::Builder' => 0, 'Plack::Middleware::Foo' => 0});
use Plack::Builder;
builder {
  enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'Foo';
};
END

test('enable_if plus', <<'END', {'Plack::Builder' => 0, 'Foo' => 0});
use Plack::Builder;
builder {
  enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } '+Foo';
};
END

test('enable_if, sub', <<'END', {'Plack::Builder' => 0, 'Plack::Middleware::Foo' => 0});
use Plack::Builder;
builder {
  enable_if sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }, 'Foo';
};
END

test('enable_if plus, sub', <<'END', {'Plack::Builder' => 0, 'Foo' => 0});
use Plack::Builder;
builder {
  enable_if sub { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }, '+Foo';
};
END

done_testing;
