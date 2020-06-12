use strict;
use warnings;

use Test::More;

my %env = (
    'foo' => {
        'bar' => 'foo.bar',
        'baz' => [ 'foo.baz.0', 'foo.baz.1' ],
        'qux' => sub { 'foo.qux' },
    },
    'empty' => { '' => 'empty' },
    'dot' => { '.' => 'dot' },
    'quotes' => { '""' => 'quotes' },
);
my @identity = qw(
    foo.bar
    foo.baz.0
    foo.baz.1
    foo.qux
    empty
    dot
    quotes
);
my %identity = map { '%('.$_.')' => $_ } @identity;
my %test = (
    'foo' => 'foo',
    '%(foo)' => '',
    'foo.baz.2' => 'foo.baz.2',
    '%(foo.baz.2)' => '',
    %identity,
);

plan tests => 2 + keys %test;

use_ok 'String::Expando';
my $exp = String::Expando->new('dot_separator' => '.', 'default_hash_keys' => ['.', '', '""']);
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
