use strict;
use warnings;
use Test::More;
use Test::Exception;
use CHI;
use Scalar::Util qw(refaddr);
use Simple::Factory;

use lib 't/lib';

subtest "should support multiple factories" => sub {
    my $factory = Simple::Factory->new(
        'Simple::Factory' => {
            'IO::File' => { 'IO::File' => { null => [ '/dev/null', 'w' ], } },
            'Foo'      => {
                build_class => 'Foo',
                build_conf  => {
                    one => { value => 1 },
                    two => { value => 2 },
                }
            }
        }
    );

    use Data::Dumper;

    isa_ok $factory->resolve( 'IO::File' => 'null' ), 'IO::File',
      'factory->resolve( IO::File => null )';
    isa_ok $factory->resolve( Foo => 'one' ), 'Foo',
      'factory->resolve( Foo => one )';
    is $factory->resolve( Foo => 'one' )->value, 1,
      'should create the right object';
};

subtest "multiple inline" => sub {
    my $factory = Simple::Factory->new(
        'Simple::Factory' => {
            'IO::File' => { null => [qw(/dev/null w)], },
            Foo        => {
                one => { value => 1 },
                two => { value => 2 },
            },
        },
        inline => 1,
    );

    isa_ok $factory->resolve( 'IO::File' => 'null' ), 'IO::File',
      'factory->resolve( IO::File => null )';
    isa_ok $factory->resolve( Foo => 'one' ), 'Foo',
      'factory->resolve( Foo => one )';
    is $factory->resolve( Foo => 'one' )->value, 1,
      'should create the right object';
};

done_testing;
