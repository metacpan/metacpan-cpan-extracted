use Test::More tests => 2 + 2*3;
BEGIN { $^W = 1 }
use strict;

BEGIN {
    require_ok('Sub::Prepend');
    use_ok('Sub::Prepend', 'prepend');
}

{
    local *foo = sub { @_ };
    prepend(foo => sub { ok(1) }, {});
    is(prototype \&foo, undef);
    &foo();
}
{
    local *foo = sub () { @_ };
    prepend(foo => sub { ok(1) }, {});
    is(prototype \&foo, '');
    &foo();
}
{
    local *foo = sub ($) { @_ };
    prepend(foo => sub { ok(1) }, {});
    is(prototype \&foo, '$');
    &foo();
}
