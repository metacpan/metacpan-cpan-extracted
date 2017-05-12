BEGIN { $^W = 1 }
use strict;
use Test::More tests => 2 + 2*2;

my $module = 'Sub::Prepend';

require_ok($module);
use_ok($module, 'prepend');

{
    local *foo = sub { bar() };
    local *bar = sub { baz() };
    local *baz = sub { caller };
    my @during;
    my @prev = foo();
    prepend(baz => sub { @during = (caller($Sub::Prepend::CALLER))[0..2] });
    my @after = foo();

    is_deeply(\@prev, \@during, 'during');
    is_deeply(\@prev, \@after, 'after');
}
{
    local *foo = sub { bar() };
    local *bar = sub { baz() };
    local *baz = sub { (caller(1))[0..2] };
    my @during;
    my @prev = foo();
    prepend(baz => sub { @during = (caller(1 + $Sub::Prepend::CALLER))[0..2] });
    my @after = foo();

    is_deeply(\@prev, \@during, 'during');
    is_deeply(\@prev, \@after, 'after');
}
