use Test::More tests => 2 + 2;
BEGIN { $^W = 1 }
use strict;
use Test::Exception;

my $module = 'Sub::Prepend';

require_ok($module);
use_ok($module, 'prepend');

sub Foo::foo { @_ }

my @p = 1 .. 3;
my @before = Foo::foo(@p);
prepend('Foo::foo' => sub { unshift @_, 'x' });
my @after = Foo::foo(@p);

is_deeply(\@before, \@p);
is_deeply(\@after, [ 'x', @p ]);
