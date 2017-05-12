
use strict;
use warnings;
use Test::More tests => 138;

{
    package My::Singleton::A;
    use Moo;
    with 'MooX::Singleton';
}
{
    package My::Singleton::A::A1;
    use Moo;
    extends 'My::Singleton::A';
}
{
    package My::Singleton::A::A2;
    use Moo;
    extends 'My::Singleton::A';

    has 'attrib' => (
        is => 'rw',
        lazy => 1,
        default => sub { "value" },
    );
}
{
    package My::Singleton::B;
    use Moo;
    with 'MooX::Singleton';

    has 'attrib' => (
        is => 'rw',
        lazy => 1,
        default => sub { "value" },
    );
}
{
    package My::Singleton::B::B1;
    use Moo;
    extends 'My::Singleton::B';
}
{
    package My::Singleton::B::B2;
    use Moo;
    extends 'My::Singleton::B';

    has 'attrib2' => (
        is => 'rw',
        lazy => 1,
        default => sub { "value" },
    );
}
{
    package My::Singleton::C;
    use Moo;
    with 'MooX::Singleton';

    has 'attrib' => (
        is => 'rw',
        lazy => 1,
        default => sub { "value" },
    );

    sub BUILD {
        my $self = shift;

        $self->attrib("BUILD replaced default");
    }
}
{
    package My::Singleton::C::C1;
    use Moo;
    extends 'My::Singleton::C';
}
{
    package My::Singleton::C::C2;
    use Moo;
    extends 'My::Singleton::C';

    has 'attrib2' => (
        is => 'rw',
        lazy => 1,
        default => sub { "value" },
    );

    sub BUILD {
        my $self = shift;

        $self->attrib2("BUILD replaced default");
    }
}
{
    package My::Singleton::C::C3;
    use Moo;
    extends 'My::Singleton::C';

    sub BUILD {
        my $self = shift;

        $self->attrib("C3->BUILD replaced default");
    }
}
{
    package My::Singleton::D;
    use Moo;
    with 'MooX::Singleton';

    has 'attrib' => (
        is => 'rw',
        lazy => 1,
        default => sub { 1 },
    );

    around BUILDARGS => sub {
        my $orig = shift;
        my ( $class, @args ) = @_;

        if ( @args % 2 != 0 ) {
            $_ *= 2 for @args;
            unshift @args, 'attrib';
        } else {
            for (my $i = 0; $i < @args; $i+=2) {
                $args[$i+1] *= 2;
            }
        }

        return $class->$orig(@args);
    };
}
{
    package My::Singleton::D::D1;
    use Moo;
    extends 'My::Singleton::D';
}
{
    package My::Singleton::D::D2;
    use Moo;
    extends 'My::Singleton::D';

    has 'attrib2' => (
        is => 'rw',
        lazy => 1,
        default => sub { 1 },
    );

    around BUILDARGS => sub {
        my $orig = shift;
        my ( $class, $arg ) = @_;

        return $class->$orig(
            attrib => $arg * 3,
            attrib2 => $arg * 4,
        );
    };
}
{
    package My::Singleton::D::D3;
    use Moo;
    extends 'My::Singleton::D';

    around BUILDARGS => sub {
        my $orig = shift;
        my ( $class, @args ) = @_;

        $_ *= 5 for @args;
        unshift @args, 'attrib';

        return $class->$orig(@args);
    };
}
{
    package My::Singleton::E;
    use Moo;
}
{
    package My::Singleton::E::E1;
    use Moo;
    extends 'My::Singleton::E';
    with 'MooX::Singleton';
}

# A
ok(! My::Singleton::A->_has_instance, "no instance created yet");
my $a = My::Singleton::A->instance;
isa_ok($a, "My::Singleton::A");
ok(My::Singleton::A->_has_instance, "instance created");

my $a2 = My::Singleton::A->instance;
isa_ok($a2, "My::Singleton::A");
is $a, $a2, 'single instance returned';
ok(My::Singleton::A->_clear_instance, "instance cleared");
ok(! My::Singleton::A->_has_instance, "no instance exists");

ok(! My::Singleton::A::A1->_has_instance, "no instance created yet");
my $aa1 = My::Singleton::A::A1->instance;
isa_ok($aa1, "My::Singleton::A::A1");
ok(My::Singleton::A::A1->_has_instance, "instance created");

my $aa12 = My::Singleton::A::A1->instance;
isa_ok($aa12, "My::Singleton::A::A1");
is $aa1, $aa12, 'single instance returned';
ok(My::Singleton::A::A1->_clear_instance, "instance cleared");
ok(! My::Singleton::A::A1->_has_instance, "no instance exists");

ok(! My::Singleton::A::A2->_has_instance, "no instance created yet");
my $aa2 = My::Singleton::A::A2->instance;
isa_ok($aa2, "My::Singleton::A::A2");
ok(My::Singleton::A::A2->_has_instance, "instance created");
is $aa2->attrib, "value", '$aa2->attrib correct';

my $aa22 = My::Singleton::A::A2->instance( attrib => "new value" );
isa_ok($aa22, "My::Singleton::A::A2");
is $aa2, $aa22, 'single instance returned';
is $aa2->attrib, "value", '$aa2->attrib correct';
ok(My::Singleton::A::A2->_clear_instance, "instance cleared");
ok(! My::Singleton::A::A2->_has_instance, "no instance exists");

# B
ok(! My::Singleton::B->_has_instance, "no instance created yet");
my $b = My::Singleton::B->instance( attrib => "new value" );
isa_ok($b, "My::Singleton::B");
ok(My::Singleton::B->_has_instance, "instance created");
is $b->attrib, "new value", '$b->attrib correct';

my $b2 = My::Singleton::B->instance;
isa_ok($b2, "My::Singleton::B");
is $b, $b2, 'single instance returned';
is $b2->attrib, "new value", '$b2->attrib correct';
ok(My::Singleton::B->_clear_instance, "instance cleared");
ok(! My::Singleton::B->_has_instance, "no instance exists");

ok(! My::Singleton::B::B1->_has_instance, "no instance created yet");
my $bb1 = My::Singleton::B::B1->instance();
isa_ok($bb1, "My::Singleton::B::B1");
ok(My::Singleton::B::B1->_has_instance, "instance created");
is $bb1->attrib, "value", '$bb1->attrib correct';

my $bb12 = My::Singleton::B::B1->instance;
isa_ok($bb12, "My::Singleton::B::B1");
is $bb1, $bb12, 'single instance returned';
ok(My::Singleton::B::B1->_clear_instance, "instance cleared");
ok(! My::Singleton::B::B1->_has_instance, "no instance exists");

ok(! My::Singleton::B::B2->_has_instance, "no instance created yet");
my $bb2 = My::Singleton::B::B2->instance(
    attrib => "new value",
    attrib2 => "another value",
);
isa_ok($bb2, "My::Singleton::B::B2");
ok(My::Singleton::B::B2->_has_instance, "instance created");
is $bb2->attrib, "new value", '$bb2->attrib correct';
is $bb2->attrib2, "another value", '$bb2->attrib2 correct';

my $bb22 = My::Singleton::B::B2->instance;
isa_ok($bb22, "My::Singleton::B::B2");
is $bb2, $bb22, 'single instance returned';
is $bb22->attrib, "new value", '$bb22->attrib correct';
is $bb22->attrib2, "another value", '$bb22->attrib2 correct';
ok(My::Singleton::B::B2->_clear_instance, "instance cleared");
ok(! My::Singleton::B::B2->_has_instance, "no instance exists");

# C
ok(! My::Singleton::C->_has_instance, "no instance created yet");
my $c = My::Singleton::C->instance();
isa_ok($c, "My::Singleton::C");
ok(My::Singleton::C->_has_instance, "instance created");
is $c->attrib, "BUILD replaced default", '$c->attrib correct';

my $c2 = My::Singleton::C->instance;
isa_ok($c2, "My::Singleton::C");
is $c, $c2, 'single instance returned';
is $c2->attrib, "BUILD replaced default", '$c2->attrib correct';
ok(My::Singleton::C->_clear_instance, "instance cleared");
ok(! My::Singleton::C->_has_instance, "no instance exists");

ok(! My::Singleton::C::C1->_has_instance, "no instance created yet");
my $cc1 = My::Singleton::C::C1->instance();
isa_ok($cc1, "My::Singleton::C::C1");
ok(My::Singleton::C::C1->_has_instance, "instance created");
is $cc1->attrib, "BUILD replaced default", '$cc1->attrib correct';

my $cc12 = My::Singleton::C::C1->instance;
isa_ok($cc12, "My::Singleton::C::C1");
is $cc1, $cc12, 'single instance returned';
is $cc12->attrib, "BUILD replaced default", '$cc12->attrib correct';
ok(My::Singleton::C::C2->_clear_instance, "instance cleared");
ok(! My::Singleton::C::C2->_has_instance, "no instance exists");

ok(! My::Singleton::C::C2->_has_instance, "no instance created yet");
my $cc2 = My::Singleton::C::C2->instance();
isa_ok($cc2, "My::Singleton::C::C2");
ok(My::Singleton::C::C2->_has_instance, "instance created");
is $cc2->attrib, "BUILD replaced default", '$cc2->attrib correct';
is $cc2->attrib2, "BUILD replaced default", '$cc2->attrib2 correct';

my $cc22 = My::Singleton::C::C2->instance;
isa_ok($cc22, "My::Singleton::C::C2");
is $cc2, $cc22, 'single instance returned';
is $cc22->attrib, "BUILD replaced default", '$cc22->attrib correct';
is $cc22->attrib2, "BUILD replaced default", '$cc22->attrib2 correct';
ok(My::Singleton::C::C1->_clear_instance, "instance cleared");
ok(! My::Singleton::C::C1->_has_instance, "no instance exists");

ok(! My::Singleton::C::C3->_has_instance, "no instance created yet");
my $cc3 = My::Singleton::C::C3->instance();
isa_ok($cc3, "My::Singleton::C::C3");
ok(My::Singleton::C::C3->_has_instance, "instance created");
is $cc3->attrib, "C3->BUILD replaced default", '$cc3->attrib correct';

my $cc32 = My::Singleton::C::C3->instance;
isa_ok($cc32, "My::Singleton::C::C3");
is $cc3, $cc32, 'single instance returned';
is $cc32->attrib, "C3->BUILD replaced default", '$cc32->attrib correct';
ok(My::Singleton::C::C3->_clear_instance, "instance cleared");
ok(! My::Singleton::C::C3->_has_instance, "no instance exists");

# D
ok(! My::Singleton::D->_has_instance, "no instance created yet");
my $d = My::Singleton::D->instance( 2 );
isa_ok($d, "My::Singleton::D");
ok(My::Singleton::D->_has_instance, "instance created");
is $d->attrib, 4, '$d->attrib correct';

my $d2 = My::Singleton::D->instance;
isa_ok($d2, "My::Singleton::D");
is $d, $d2, 'single instance returned';
is $d2->attrib, 4, '$d2->attrib correct';
ok(My::Singleton::D->_clear_instance, "instance cleared");
ok(! My::Singleton::D->_has_instance, "no instance exists");

ok(! My::Singleton::D::D1->_has_instance, "no instance created yet");
my $dd1 = My::Singleton::D::D1->instance( 3 );
isa_ok($dd1, "My::Singleton::D::D1");
ok(My::Singleton::D::D1->_has_instance, "instance created");
is $dd1->attrib, 6, '$dd1->attrib correct';

my $dd12 = My::Singleton::D::D1->instance;
isa_ok($dd12, "My::Singleton::D::D1");
is $dd1, $dd12, 'single instance returned';
is $dd12->attrib, 6, '$dd12->attrib correct';
ok(My::Singleton::D::D1->_clear_instance, "instance cleared");
ok(! My::Singleton::D::D1->_has_instance, "no instance exists");

ok(! My::Singleton::D::D2->_has_instance, "no instance created yet");
my $dd2 = My::Singleton::D::D2->instance( 4 );
isa_ok($dd2, "My::Singleton::D::D2");
ok(My::Singleton::D::D2->_has_instance, "instance created");
is $dd2->attrib, 24, '$dd2->attrib correct';
is $dd2->attrib2, 32, '$dd2->attrib2 correct';

my $dd22 = My::Singleton::D::D2->instance;
isa_ok($dd22, "My::Singleton::D::D2");
is $dd2, $dd22, 'single instance returned';
is $dd22->attrib, 24, '$dd22->attrib correct';
is $dd22->attrib2, 32, '$dd22->attrib2 correct';
ok(My::Singleton::D::D2->_clear_instance, "instance cleared");
ok(! My::Singleton::D::D2->_has_instance, "no instance exists");

ok(! My::Singleton::D::D3->_has_instance, "no instance created yet");
my $dd3 = My::Singleton::D::D3->instance( 5 );
isa_ok($dd3, "My::Singleton::D::D3");
ok(My::Singleton::D::D3->_has_instance, "instance created");
is $dd3->attrib, 50, '$dd3->attrib correct';

my $dd32 = My::Singleton::D::D3->instance;
isa_ok($dd32, "My::Singleton::D::D3");
is $dd3, $dd32, 'single instance returned';
is $dd32->attrib, 50, '$dd32->attrib correct';
ok(My::Singleton::D::D3->_clear_instance, "instance cleared");
ok(! My::Singleton::D::D3->_has_instance, "no instance exists");

# E
my $e = My::Singleton::E->new;
isa_ok($e, "My::Singleton::E");
ok(! My::Singleton::E->can('instance'), "parent class is not a singleton");

my $e2 = My::Singleton::E->new;
isa_ok($e2, "My::Singleton::E");
isnt $e, $e2, 'different objects returned';

ok(! My::Singleton::E::E1->_has_instance, "no instance created yet");
my $ee1 = My::Singleton::E::E1->instance;
isa_ok($ee1, "My::Singleton::E::E1");
ok(My::Singleton::E::E1->_has_instance, "instance created");

my $ee12 = My::Singleton::E::E1->instance;
isa_ok($ee12, "My::Singleton::E::E1");
is $ee1, $ee12, 'single instance returned';
ok(My::Singleton::E::E1->_clear_instance, "instance cleared");
ok(! My::Singleton::E::E1->_has_instance, "no instance exists");


