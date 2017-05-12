use strict;
use warnings;
use Test::More tests => 8;
use Package::FromData;
use Test::Exception;
use Scalar::Util qw(blessed);

{ package Foo::Bar::Baz; sub new { bless \my $heart, shift } }

my $packages = { 
    'Foo::Bar' => {
        constructors   => ['new'],        # my $foo_bar = Foo::Bar->new
        static_methods => {               # Foo::Bar->method
            next_word => [                # Foo::Bar->next_word
                ['foo']       => 'bar',   # Foo::Bar->next_word('foo') = bar
                ['hello']     => 'world',
                [qw/bar baz/] => 'baz',   # Foo::Bar->next_word(qw/foo bar/) 
                                          #    = baz
                'default_value'
            ],
            one => [ 1 ],                 # Foo::Bar->one = 1
        },
        methods => {
            wordify => [ '...' ],         # $foo_bar->wordify = '...'
            # Foo::Bar->wordify = <exception>
            
            # baz always returns Foo::Bar::Baz->new
            baz     => [ { new => 'Foo::Bar::Baz' } ],
        },
        functions => {
            map_foo_bar => [ 
                ['foo'] => 'bar', 
                ['bar'] => 'foo',
            ],
            context     => {
                scalar => 'called in scalar context',
                list   => [qw/called in list context/],
            }
        },
        variables => {
            '$VERSION' => '42',           # $Foo::Bar::VERSION
            '@ISA'     => ['Foo'],        # @Foo::Bar::ISA
            '%FOO'     => {Foo => 'Bar'}, # %Foo::Bar::FOO
        },
    },
};

create_package_from_data($packages);

my $fb = Foo::Bar->new;
ok blessed $fb;
isa_ok $fb->baz, 'Foo::Bar::Baz';     
is($fb->wordify, '...');        
is($fb->next_word('foo'), 'bar');
is(Foo::Bar->next_word('foo'), 'bar');
dies_ok { Foo::Bar->baz };
is(Foo::Bar::map_foo_bar('foo'), 'bar');
is($Foo::Bar::VERSION, 42);
