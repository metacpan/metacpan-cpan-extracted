use Test::More tests => 2 + 3;
BEGIN { $^W = 1 }
use strict;
use Test::Exception;

my $module = 'Sub::Prepend';

require_ok($module);
use_ok($module, 'prepend');

sub foo { @_ }

my @p = 1 .. 3;
my @before = foo(@p);
prepend(foo => sub { unshift @_, 'x' });
my @after = foo(@p);

is_deeply(\@before, \@p);
is_deeply(\@after, [ 'x', @p ]);

{
    package Foo;
    sub undef_sub ($);
    ::throws_ok
        { scalar ::prepend(undef_sub => sub { 1 }) }
        qr/^$module: Subroutine &Foo::undef_sub not defined /,
        'undef'
    ;
}
