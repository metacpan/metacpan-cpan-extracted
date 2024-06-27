use v5.22;
use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval {require Object::Pad}) {
        plan skip_all => "Object::Pad required for testing Object::Pad compatibility";
        exit();
    }
}

plan tests => 17;

use Object::Pad;
use Multi::Dispatch;

class Demo {
    field $x :param;
    field $y :param;

    my $status = 'STATUS';

    multimethod show ($a, $b) {
        Test::More::isa_ok( $self, 'Demo' => '$self');
        return [$a, $b, $x, $y];
    }

    multimethod show () {
        return [$x, $y];
    }

    multimethod status :common () {
        Test::More::is( $class, 'Demo' => '$class');
        return $status;
    }

    multimethod status :common ($prefix) {
        return "$prefix $status";
    }

    method test_subdemo {
        class SubDemo {
            field $sub_x : param reader;

            method nonmulti               { "non-multi: $sub_x"        }
            multimethod ismulti ()        { "is multi: $sub_x"         }
            multimethod ismulti ($prefix) { "is $prefix multi: $sub_x" }
        }

        my $subobj = SubDemo->new(sub_x => 'sub x');

        Test::More::is $subobj->nonmulti(),     'non-multi: sub x'    => 'non-multi()';
        Test::More::is $subobj->ismulti(),      'is multi: sub x'     => 'ismulti()';
        Test::More::is $subobj->ismulti('pre'), 'is pre multi: sub x' => 'ismulti(pre)';
    }

}

my $obj = Demo->new(x=>1, y=>2);

is_deeply $obj->show('a','b'), ['a', 'b', 1, 2] => 'show(a,b)';
is_deeply $obj->show(),        [1, 2]           => 'show()';

is eval { $obj->show(86) }, undef()                           => 'show(86)';
like $@, qr/No suitable variant for call to multimethod show/ => 'exception is correct';

is( Demo->status(), 'STATUS'  => 'status()' );
is( Demo->status('PREFIX'), 'PREFIX STATUS'  => 'status(PREFIX)' );

$obj->test_subdemo();



# Class inheritance...

class DerDemo :isa(Demo) {
    multimethod show () {
        return 'DerDemo show';
    }

}


my $derobj = DerDemo->new(x=>1, y=>2);

is_deeply $derobj->show('a','b'), ['a', 'b', 1, 2] => 'derived show(a,b)';
is        $derobj->show(),        'DerDemo show'   => 'derived show()';


# Skip for now, as it doesn't work (and is so documented)...
if (0) {
    # Role composition...

    role WithArgs {
        multimethod foo ($arg1       ) { return "R1: $arg1" }
        multimethod foo ($arg1, $arg2) { return "R2: $arg1, $arg2" }
    }

    class RoleDemo :does(WithArgs) {
        multimethod foo ($arg1) { return "C1: $arg1" }
    }

    my $roleobj = RoleDemo->new();

    is $roleobj->foo(1,2), "R2: 1, 2" => 'Multi composed in from role';
    is $roleobj->foo(3),   "C1: 3"    => 'Multi in class overrides';
}


# Constraints involving object status...

class Constraints {
    field $value :param :reader;

    multimethod foo ($arg)
                            { ::ok $arg eq 'unconstrained' => 'unconstrained' }

    multimethod foo ($arg :where({ $value eq 'constrained' }))
                            { ::ok $arg eq 'constrained' => 'constrained' }

    multimethod foo ($arg :where({ $self->value eq 'methodical' }))
                            { ::ok $arg eq 'methodical' => 'methodical' }
}

my $cons_obj;

$cons_obj = Constraints->new(value => 'unconstrained');
$cons_obj->foo('unconstrained');

$cons_obj = Constraints->new(value => 'constrained');
$cons_obj->foo('constrained');

$cons_obj = Constraints->new(value => 'methodical');
$cons_obj->foo('methodical');

done_testing();

