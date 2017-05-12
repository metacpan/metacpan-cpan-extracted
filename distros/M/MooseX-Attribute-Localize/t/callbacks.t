use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep 0.111;

{
    package Foo;

    use Moose;
    use MooseX::Attribute::Localize;

    has bar => (
        is => 'ro',
        traits => [ qw/ Localize / ],
        localize_push => sub {
            my $self = shift;
            $self->local_push(@_);
        },
        localize_pop => sub {
            my $self = shift;
            $self->local_pop(@_);
        },
        handles => {
            local_bar => 'localize',
            bar_stack => 'localize_stack',
        },
    );

    has baz => (
        is => 'ro',
        traits => [ qw/ Localize / ],
        localize_push => 'local_push',
        localize_pop  => 'local_pop',
        handles => {
            local_baz => 'localize',
            baz_stack => 'localize_stack',
        },
    );

    our( $in, $out );

    sub local_push { $in = \@_ }
    sub local_pop { $out = \@_ }

}

my $foo = Foo->new( bar => 1, baz => 1 );

for my $attribute ( qw/ bar baz / ) {
    subtest $attribute => sub {
        my $m = "local_$attribute";
        my $stack = join '_', $attribute, 'stack';
        $Foo::in = $Foo::out = undef;
        {
            cmp_deeply [ $foo->$stack ] => [ 1 ], "initial stack";
            is scalar $foo->$stack => 1, "size 1";
            {
                my $s = $foo->$m(2);
                cmp_deeply $Foo::in => [ obj_isa('Foo'), 2, 1, obj_isa('Moose::Meta::Attribute') ];
                cmp_deeply [ $foo->$stack ] => [ 2, 1 ];
                is scalar $foo->$stack => 2, "size 2";
            }
            cmp_deeply $Foo::out => [ obj_isa('Foo'), 1, 2, obj_isa('Moose::Meta::Attribute') ]
                or diag explain $Foo::out;
            cmp_deeply [ $foo->$stack ] => [ 1 ];
            is scalar $foo->$stack => 1, "size 1";
        }
    };
}






