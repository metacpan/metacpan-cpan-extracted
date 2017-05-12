#!perl -w

use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);
use Params::Util qw(_INSTANCE); # 0.35 provides a XS implementation
use Scalar::Util qw(blessed);
use Scalar::Util::Instance { for => 'Foo', as => 'is_a_Foo' };

signature
    'Data::Util'   => \&is_instance,
    'Params::Util' => \&_INSTANCE,
    'Scalar::Util' => \&blessed,
    'Scalar::Util::Instance' => \&is_a_Foo,
;

sub noop{ }

BEGIN{ eval{ require MRO::Compat } }

BEGIN{
    package Base;
    sub new{
        bless {} => shift;
    }
    
    package Foo;
    our @ISA = qw(Base);

    package Bar;
    our @ISA = qw(Foo);
    package Baz;
    our @ISA = qw(Foo);
    package Diamond;
    use mro 'c3';
    our @ISA = qw(Bar Baz);

    package NonFoo;
    our @ISA = qw(Base);
}

foreach my $x (Foo->new, Diamond->new, NonFoo->new, undef, {}){
    print 'For ', neat($x), "\n";

    my $n = 100;

    cmpthese -1 => {
        'blessed' => sub{
            for(1 .. $n){
                1 if blessed($x) && $x->isa('Foo');
            }
        },
        '_INSTANCE' => sub{
            for(1 .. $n){
                1 if _INSTANCE($x, 'Foo');
            }
        },
        'is_instance' => sub{
            for(1 .. $n){
                1 if is_instance($x, 'Foo');
            }
        },
        'is_a_Foo' => sub{
            for(1 .. $n){
                1 if is_a_Foo($x);
            }
        },
        'noop' => sub{
            for(1 .. $n){
                1 if noop($x);
            }
        },
    };

    print "\n";
}
