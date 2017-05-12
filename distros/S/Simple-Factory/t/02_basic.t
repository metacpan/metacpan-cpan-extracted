use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use CHI;
use Scalar::Util qw(refaddr);
use Simple::Factory;

use lib 't/lib';

subtest "basic test" => sub {
    my $ref = { epoch => 2 };
    my $factory = Simple::Factory->new(
        build_class  => 'DateTime',
        build_method => 'from_epoch',
        build_conf   => {
            one      => { epoch => 1 },
            two      => { epoch => 2 },
            thousand => { epoch => 1000 }
        },
        fallback => sub { epoch => 60000 },
    );

    ok !$factory->silence, 'silence is false by default';
    ok $factory->autoderef, 'autoderef should be true';

    is $factory->resolve('one')->epoch, 1, 'should be one';
    is $factory->resolve('two')->epoch, 2, 'should be two ( from ref ref )';
    is $factory->resolve('thousand')->epoch, 1000,
      'should be thousand ( by arrayref )';
    is $factory->resolve(1024)->epoch, 60000, 'should call fallback';

    my $a = $factory->resolve('one');
    my $b = $factory->resolve('one');

    ok !$factory->has_cache, 'should not had cache';
    ok refaddr($a) ne refaddr($b),
      'should return different instances without cache';

};

subtest 'cache' => sub {
    my $hash    = {};
    my $factory = Simple::Factory->new(
        build_class  => 'DateTime',
        build_method => 'from_epoch',
        build_conf   => { now => { epoch => time } },
        cache        => CHI->new( driver => 'RawMemory', datastore => $hash )
    );

    my $a = $factory->resolve('now');
    my $b = $factory->resolve('now');

    ok $factory->has_cache, 'should had cache';
    ok refaddr($a) eq refaddr($b),
      'should return the same instances with cache';
};

subtest "class IO::File" => sub {
    my $factory = Simple::Factory->new(
        build_class => 'IO::File',
        build_conf  => { null => [qw(/dev/null w)], },
    );

    isa_ok $factory->resolve('null'), 'IO::File', 'builder->resolve( null )';

    throws_ok {
        $factory->resolve('not exist');
    }
    qr/instance of 'IO::File' named 'not exist' not found/, 'should die';
};

subtest "class IO::File with simple args" => sub {
    my $factory =
      Simple::Factory->new( 'IO::File' => { null => [qw(/dev/null w)], }, );

    isa_ok $factory->resolve('null'), 'IO::File', 'builder->resolve( null )';
};

subtest "should autoderef" => sub {
    my $ref    = { value => 2 };
    my $six    = 6;
    my $glob   = *STDOUT;
    my $regexp = qr/regexp/;

    my $factory = Simple::Factory->new(
        Foo => {
            a => { value => 1 },    # ref hash
            b => \$ref,                     # ref ref
            c => [ value => 3 ],            # ref array
            d => sub { value => 4 },        # ref code
            e => sub { value => $_[0] },    # ref code who uses key
            f => 5,                         # no ref
            g => \$six,                     # ref scalar
            h => *STDOUT,                   # GLOB
            i => \$glob,                    # ref GLOB
            y => $regexp,                   # regexp
            z => [],                        # empty ref array
        },
    );

    is $factory->resolve('a')->value, 1,   'value of x should be 1';
    is $factory->resolve('b')->value, 2,   'value of b should be 2';
    is $factory->resolve('c')->value, 3,   'value of c should be 3';
    is $factory->resolve('d')->value, 4,   'value of d should be 4';
    is $factory->resolve('e')->value, 'e', 'value of e should be e';
    is $factory->resolve('f')->value, 5,   'value of f should be 5';
    is $factory->resolve('g')->value, 6,   'value of g should be 6';
    is $factory->resolve('z')->value, 0,   'value of z should be 0 ( default )';

    my $instance;
    warning_like {
        $instance = $factory->resolve('y');
    }
    { carped => qr/cant autoderef argument ref\('Regexp'\) for class 'Foo'/ },
      'should carp - cant defer regexp';

    isa_ok $instance, 'Foo', 'instance';
    is $instance->value, $regexp, 'should contains regexp';

    is $factory->resolve('h')->value, $glob, 'value of h should be *::STDOUT';
    is $factory->resolve('i')->value, $glob, 'value of h should be *::STDOUT';
};

subtest "shold critique the missing of build_conf and build_class" => sub {

    throws_ok {
        Simple::Factory->new();
    }
    qr/Missing required arguments: build_class, build_conf/,
      'should die: missing arguments in new';

    throws_ok {
        Simple::Factory->new('Foo');
    }
    qr/Missing required arguments: build_conf/,
      'should die if using only one arg';
};

subtest "should critique the missing of build_method" => sub {
    throws_ok {
        Simple::Factory->new( Foo => { a => 1 }, build_method => 'not_exists' );
    }
    qr/class 'Foo' does not support build method: not_exists/,
      'should die: Foo has no method "not_exists"';
};

done_testing;
