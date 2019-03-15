use strict;
use warnings;
use Test::More import => [qw(ok is is_deeply like note done_testing)];
use Test::AutoMock qw(mock manager);

my $mock = mock(
    methods => {
        'hoge->bar' => sub { 'bar' },
        'hoge->boo' => 'boo',
        'foo->hoge' => sub { 'hoge' },
        'abc->def->ghi' => sub { 'ghi' },
    },
);

manager($mock)->add_method('foo->bar' => 'bar');

# define methods for children
my $abc = manager($mock)->child('abc');
$abc->add_method(jkl => sub { "jkl$_[0]" });
$abc->add_method(mno => 'mno');

{
    my $ret = eval {
        manager($mock)->add_method('abc->def' => 'def');
        1;
    };
    like $@, qr/`def` has already been defined as a field\b/;
    is $ret, undef;
}

{
    my $ret = eval {
        manager($mock)->add_method('abc->def->ghi->jkl' => 'jkl');
        1;
    };
    like $@, qr/`ghi` has already been defined as a method\b/;
    is $ret, undef;
}

{
    my $ret = eval {
        manager($mock)->add_method('hoge->bar' => 'bar');
        1;
    };
    like $@, qr/`bar` has already been defined as a method\b/;
    is $ret, undef;
}

is_deeply [manager($mock)->calls], [],
          q(hasn't been called any methods yet);

is $mock->hoge->bar, 'bar';
is $mock->hoge->boo, 'boo';
is $mock->foo->hoge, 'hoge';
is $mock->abc->def->ghi, 'ghi';
is $mock->foo->bar, 'bar';
is $mock->abc->jkl('JKL'), 'jklJKL';
is $mock->abc->mno, 'mno';

my $invalid_mock = eval {
    mock(
        methods => {
            'hoge->foo' => 'foo',
            'hoge->foo->bar' => 'bar',
        },
    );
};
ok $@ and note $@;
is $invalid_mock, undef;

done_testing;
