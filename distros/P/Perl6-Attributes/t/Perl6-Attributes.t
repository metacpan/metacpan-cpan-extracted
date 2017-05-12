use Test::More tests => 8;

BEGIN { use_ok('Perl6::Attributes') };

is(q($.foo), q($self->{'foo'}), 'scalar');
is(q(@.foo), q(@{$self->{'foo'}}), 'array');
is(q(%.foo), q(%{$self->{'foo'}}), 'hash');
is(q(&.foo), q(&{$self->{'foo'}}), 'code');
is(q($.x),   q($self->{'x'}), 'single letter');
is(q(./foo), q($self->foo), 'method call');
is(q(./foo(3)), q($self->foo(3)), 'method call with arguments');

# vim: ft=perl :
