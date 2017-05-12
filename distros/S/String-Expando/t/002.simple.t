use strict;
use warnings;

use Test::More;

my %env = (
    'bar' => 'BAR!',
);
my %test = (
    ''          => '',
    'foo'       => 'foo',
    '%(foo)'    => '',
    '%(bar)'    => 'BAR!',
    'x%(bar)yz' => 'xBAR!yz',
    '\123'      => '123',
    '\\123'     => '\123',
    '\%(abc)'   => '\\',
    '%(xyz'     => '%(xyz',
);

plan tests => 2 + keys %test;

use_ok 'String::Expando';
my $exp = String::Expando->new;
ok $exp, 'instantiate';

foreach my $str (sort keys %test) {
    my $result = $test{$str};
    is $exp->expand($str, \%env), $result, "$str -> $result";
}

__END__
is $exp->expand(''),       ''
is $exp->expand('foo'),    'foo', 'foo';
is $exp->expand('%(foo)'), '', '%(foo)';
is $exp->expand('%(foo)', { qw(foo bar) }), 'bar', '%(foo) -> bar';
