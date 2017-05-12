use strict;
use warnings;

use Test::More 'tests' => 10;

package My::Class; {
    use Object::InsideOut;

    my @oo : Field('acc'=>'oo', 'return'=>'old');
    my @nn : Field('acc'=>'nn', 'return'=>'new');
    my @ss : Field({'acc'=>'ss', 'return'=>'self'});
    my @xx : Field('acc'=>'xx');
}

package main;

MAIN:
{
    my $obj = My::Class->new();

    my $ret = $obj->oo('test');
    ok(! defined($ret)                  => 'undef on old');
    $ret = $obj->oo();
    is($ret, 'test'                     => 'Get okay');
    $ret = $obj->oo('xxx');
    is($ret, 'test'                     => 'Old return value');
    $ret = $obj->oo();
    is($ret, 'xxx'                      => 'Get okay');

    $ret = $obj->nn('zip');
    is($ret, 'zip'                      => 'New return value');
    $ret = $obj->nn();
    is($ret, 'zip'                      => 'Get okay');

    $ret = $obj->ss('jump');
    is($ret, $obj                       => 'Self return value');
    $ret = $obj->ss();
    is($ret, 'jump'                     => 'Get okay');

    $ret = $obj->xx('foo');
    is($ret, 'foo'                      => 'Default return value');
    $ret = $obj->xx();
    is($ret, 'foo'                      => 'Get okay');
}

exit(0);

# EOF
