use strict;
use warnings;
use Test::More;
use Test::Exception;
use Simple::Factory;
use CHI;
use Scalar::Util qw(refaddr);
use lib 't/lib';

subtest "should add new conf" => sub {
    my $factory =
      Simple::Factory->new( Foo => { a => 1, b => 2 }, autoderef => 0 );

    throws_ok { $factory->resolve('c') }
    qr/instance of 'Foo' named 'c' not found/, 'should die: no conf for key c';

    $factory->add_build_conf_for( c => 3 );

    my $object;
    lives_ok { $object = $factory->resolve('c') }
    'should not die, conf for key c added';

    isa_ok $object, 'Foo', 'object (c)';

    is $object->value, 3, 'should create the right instance';
};

subtest "should die if will override one existing configuration" => sub {
    my $factory =
      Simple::Factory->new( Foo => { a => 1, b => 2 }, autoderef => 0 );

    lives_ok { $factory->add_build_conf_for( c => 3, not_override => 1 ) }
    'should not die: c does not exist yet';

    throws_ok {
        $factory->add_build_conf_for( c => 3, not_override => 1 );
    }
    qr/cannot override exiting configuration for key 'c'/,
      'should die: c already exists';

    lives_ok { $factory->add_build_conf_for( c => 3, not_override => 0 ) }
    'should not die: c should be override';

    lives_ok { $factory->add_build_conf_for( c => 3 ) }
    'should not die: c should be override (default)';
};

subtest "should substitute conf and clear cache" => sub {
    my $hash    = {};
    my $factory = Simple::Factory->new(
        Foo       => { a              => 1,           b         => 2 },
        autoderef => 0,
        cache     => CHI->new( driver => 'RawMemory', datastore => $hash )
    );

    my $a = $factory->resolve('a');

    isa_ok $a, 'Foo', 'a';
    is $a->value, 1, 'value should be 1';

    my $old_refaddr_for_a = refaddr($a);
    my $old_refaddr_for_b = refaddr( $factory->resolve('b') );

    $factory->add_build_conf_for( a => 1000 );

    $a = $factory->resolve('a');

    isa_ok $a, 'Foo', 'new a';
    is $a->value, 1000, 'value now is 1000';

    ok refaddr($a) ne $old_refaddr_for_a, 'should purge the cache';
    ok refaddr( $factory->resolve('b') ) eq $old_refaddr_for_b,
      'should not touch in the entire cache, only for a';
};

done_testing;
