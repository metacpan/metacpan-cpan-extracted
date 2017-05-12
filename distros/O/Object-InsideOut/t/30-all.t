use strict;
use warnings;

use Test::More 'tests' => 11;

package My::Class; {
    use Object::InsideOut;

    sub is_scalar { return (! ref(shift)); }

    sub is_int {
        my $arg = $_[0];
        return (Scalar::Util::looks_like_number($arg) &&
                (int($arg) == $arg));
    }

    my @data :Field('all'=>'data', 'type' => 'num');
    my @info :Field({ 'std'=>'info', 'arg'=>'scalar', 'type' => \&My::Class::is_scalar });
    my @foo  :Field
             :Acc(foo) :Name(foo)
             :Arg(FOO) :Type(name => \&My::Class::is_int);
    my @bar  :Field('all'=>'bar', 'type' => 'ARRAY');
    my @baz  :Field
             :All(baz)
             :Type(hash);
    my @bork :Field
             :Def('bork')
             :Get(bork);
    my %faz  :Field
             :Arg('zzz')
             :Def('snooze');

    sub init :Init
    {
        my ($self, $args) = @_;
        Test::More::is($faz{$$self}, 'snooze' => 'default assigned before :Init');
    }
}

package main;

MAIN:
{
    my $obj = My::Class->new(
        'data'   => 5.5,
        'scalar' => 'foo',
        'FOO'    => 99,
        'bar'    => 'bar',
        'baz'    => { 'hello' => 'world' },
    );

    ok($obj                             => 'Object created');
    is($obj->data(),     5.5            => 'num field');
    is($obj->get_info(), 'foo'          => 'scalar field');
    is($obj->foo(),      99             => 'int field');
    is_deeply($obj->bar(), [ 'bar' ]    => 'list field');
    is_deeply($obj->baz(), { 'hello' => 'world' }       => 'hash field');
    is($obj->bork(), 'bork',            => 'default');

    eval { My::Class->new('data' => 'foo'); };
    like($@, qr/must be a number/       => 'Type check');

    eval { My::Class->new('scalar' => $obj); };
    like($@, qr/failed type check/      => 'Type check');

    eval { My::Class->new('FOO' => 4.5); };
    like($@, qr/failed type check/      => 'Type check');
}

exit(0);

# EOF
