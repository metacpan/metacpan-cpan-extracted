use strict;
use warnings;

use Test::More tests => 50;

my $CLASS = 'Perl6::Roles';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# create 2 roles with conflicting methods

{
    package rFoo;
    use base 'Perl6::Roles';
    
    sub foo { 'rFoo::foo' }
    sub baz { 'rFoo::baz' }
}

{
    package rBar;
    use base 'Perl6::Roles';

    sub bar { 'rBar::bar' }    
    sub baz { 'rBar::baz' }    
}

# try applying them to packages

{
    package FooBar::With::Conflict;
    
    eval {
        rFoo->apply(__PACKAGE__);
        rBar->apply(__PACKAGE__);    
    };
    Test::More::ok($@, '... this should die from an unresolved method conflict');
}

{
    package FooBar::With::Out::Conflict;

    sub baz { 'FooBar::With::Out::Conflict::baz' }

    eval {
        rFoo->apply(__PACKAGE__);
        rBar->apply(__PACKAGE__);    
    };
    Test::More::ok(!$@, '... this should not die because we resolved the method conflict');
}

ok(FooBar::With::Out::Conflict->can('baz'), '... make sure our &baz method is there');
ok(FooBar::With::Out::Conflict->can('foo'), '... make sure our &foo method is composed in');
ok(FooBar::With::Out::Conflict->can('bar'), '... make sure our &baz method is composed in');

is(FooBar::With::Out::Conflict->baz(), 
  'FooBar::With::Out::Conflict::baz', 
  '... got the right value from &baz');
is(FooBar::With::Out::Conflict->foo(), 'rFoo::foo', '... got the right value from &foo');
is(FooBar::With::Out::Conflict->bar(), 'rBar::bar', '... got the right value from &bar');

## ----------------------------------------------------------------------------

# now create a role which consumes both

{
    package rFooBar;
    use base 'Perl6::Roles';

    sub foo_bar { 'rFooBar::foo_bar' }

    eval {
        rFoo->apply(__PACKAGE__);
        rBar->apply(__PACKAGE__);    
    };
    Test::More::ok(!$@, '... this should not die because subroles are not consumed');  
}

ok(rFooBar->does('rFoo'), '... rFooBar does rFoo');
ok(rFooBar->does('rBar'), '... rFooBar does rBar');

ok(!rFooBar->can('baz'), '... rFooBar should not have consumed the subroles yet');
ok(rFooBar->can('foo_bar'), '... rFooBar does have a &foo_bar method');

## now composed it, and get the conflict

{
    package FooBar::With::Conflict2;

    eval {
        rFooBar->apply(__PACKAGE__);
    };
    Test::More::ok($@, '... this should die from an unresolved method conflict');
}

## now compose, and let it get dis-ambiguated

{
    package FooBar::With::Out::Conflict2;

    sub baz { 'FooBar::With::Out::Conflict2::baz' }

    eval {
        rFooBar->apply(__PACKAGE__);
    };
    Test::More::ok(!$@, "... this shouldn't die since we resolved the method conflict");
}

ok(FooBar::With::Out::Conflict2->can('baz'), '... make sure our &baz method is there');
ok(FooBar::With::Out::Conflict2->can('foo'), '... make sure our &foo method is composed in');
ok(FooBar::With::Out::Conflict2->can('bar'), '... make sure our &baz method is composed in');
ok(FooBar::With::Out::Conflict2->can('foo_bar'), '... make sure our &foo_baz method is composed in');

is(FooBar::With::Out::Conflict2->foo_bar(), 
  'rFooBar::foo_bar', 
  '... got the right value from &foo_bar');
is(FooBar::With::Out::Conflict2->baz(), 
  'FooBar::With::Out::Conflict2::baz', 
  '... got the right value from &baz');  
is(FooBar::With::Out::Conflict2->foo(), 'rFoo::foo', '... got the right value from &foo');
is(FooBar::With::Out::Conflict2->bar(), 'rBar::bar', '... got the right value from &bar');

## ----------------------------------------------------------------------------

## now resolve the method conflict in the role

{
    package rFooBar2;
    use base 'Perl6::Roles';

    sub baz { 'rFooBar2::baz' }

    eval {
        rFoo->apply(__PACKAGE__);
        rBar->apply(__PACKAGE__);    
    };
    Test::More::ok(!$@, '... this should not die because subroles are not consumed');  
}

ok(rFooBar2->does('rFoo'), '... rFooBar2 does rFoo');
ok(rFooBar2->does('rBar'), '... rFooBar2 does rBar');

ok(rFooBar2->can('baz'), '... rFooBar2 should not have consumed the subroles yet');

SKIP: {
    skip "roles disambiguating subroles' conflicts unspec'ed as of yet", 7;
    {
        package FooBar::With::Out::Conflict3;

        eval {
            rFooBar2->apply(__PACKAGE__);
        };
        Test::More::ok(!$@, '... this should not die because we resolved the method conflict');
    }

    ok(FooBar::With::Out::Conflict3->can('baz'), '... make sure our &baz method is there');
    ok(FooBar::With::Out::Conflict3->can('foo'), '... make sure our &foo method is composed in');
    ok(FooBar::With::Out::Conflict3->can('bar'), '... make sure our &baz method is composed in');

    is(FooBar::With::Out::Conflict3->baz(), 
        'rFooBar2::baz', 
        '... got the right value from &baz',
    );
    is(FooBar::With::Out::Conflict3->foo(), 'rFoo::foo', '... got the right value from &foo');
    is(FooBar::With::Out::Conflict3->bar(), 'rBar::bar', '... got the right value from &bar');
}

{
    package rBaz;
    use base 'Perl6::Roles';
    
    sub floober { 'rBaz::floober' }
}

{
    package rFooBarBaz;
    use base 'Perl6::Roles';

    eval {
        rFooBar->apply(__PACKAGE__);
        rBaz->apply(__PACKAGE__);    
    };
    Test::More::ok(!$@, '... this should not die because subroles are not consumed');  
}

{
    package FooBarBaz::With::Conflict;
    
    eval {
        rFooBarBaz->apply(__PACKAGE__);
    };
    Test::More::ok($@, '... this should die from an unresolved method conflict');
}

{
    package FooBarBaz::With::Out::Conflict;

    sub baz { 'FooBarBaz::With::Out::Conflict::baz' }

    eval {
        rFooBarBaz->apply(__PACKAGE__);
    };
    Test::More::ok(!$@, '... this should not die because we resolved the method conflict');
}

ok(FooBarBaz::With::Out::Conflict->can('baz'), '... make sure our &baz method is there');
ok(FooBarBaz::With::Out::Conflict->can('foo'), '... make sure our &foo method is composed in');
ok(FooBarBaz::With::Out::Conflict->can('bar'), '... make sure our &baz method is composed in');
ok(FooBarBaz::With::Out::Conflict->can('floober'), '... make sure our &baz method is composed in');

ok(FooBarBaz::With::Out::Conflict->does('rFoo'), '... FooBarBaz does rFoo');
ok(FooBarBaz::With::Out::Conflict->does('rBar'), '... FooBarBaz does rBar');
ok(FooBarBaz::With::Out::Conflict->does('rFooBar'), '... FooBarBaz does rFooBar');
ok(FooBarBaz::With::Out::Conflict->does('rBaz'), '... FooBarBaz does rBaz');

is(FooBarBaz::With::Out::Conflict->baz(), 
    'FooBarBaz::With::Out::Conflict::baz', 
    '... got the right value from &baz');
is(FooBarBaz::With::Out::Conflict->foo(),
    'rFoo::foo',
    '... got the right value from &foo');
is(FooBarBaz::With::Out::Conflict->bar(),
    'rBar::bar',
    '... got the right value from &bar');
is(FooBarBaz::With::Out::Conflict->floober(),
    'rBaz::floober',
    '... got the right value from &floober');
