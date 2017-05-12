use strict;
use warnings;
use Test::More;
use Nephia::Incognito;
use t::Util 'mock_env';

is(
    Nephia::Incognito->_incognito_namespace('Foo'), 
    'Nephia::Incognito::Foo', 
    'incognito namespace'
);

Nephia::Incognito->incognito(app => sub { [200, [], 'Foo'] });
Nephia::Incognito->incognito(caller => 'Funny', app => sub { [200, [], 'Bar'] });

my $x = Nephia::Incognito->unmask;
my $y = Nephia::Incognito->unmask('Funny');

isa_ok $x, 'Nephia::Core';
isa_ok $y, 'Nephia::Core';

is_deeply( $x->run->(mock_env), [200, [], ['Foo']] );
is_deeply( $y->run->(mock_env), [200, [], ['Bar']] );

done_testing;
