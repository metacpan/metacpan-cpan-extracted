use strict;
use warnings;
use Test::More;

{

    package Counter;
    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter name => (
        is       => 'ro',    # this is mandatory on Moo
        required => 1,       # mark the parameter "name" as "required"
    );

    role {
        my ( $p, $mop ) = @_;

        my $name = $p->name;    # $p->{name} will also work

        $mop->has(
            $name => (
                is      => 'rw',
                default => sub {0},
            )
        );

        $mop->method(
            "increment_$name" => sub {
                my $self = shift;
                $self->$name( $self->$name + 1 );
            }
        );

        $mop->method(
            "reset_$name" => sub {
                my $self = shift;
                $self->$name(0);
            }
        );
    };
    1;

}

{

    package Some::Parametric::Role::With::Default::Parameters;
    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter foo => ( is => 'ro', default => sub {"bar"} );

    role {
        my ( $params, $mop ) = @_;

        my $foo = $params->foo;

        $mop->has( $foo => ( is => 'rw', required => 1 ) );
    };
    1;
}

{

    package MyGame::Weapon;
    use Moo;
    use MooX::Role::Parameterized::With;

    with Counter => {
        name => 'enchantment',
    };

    1;

}

{

    package MyGame::Wand;
    use Moo;
    use MooX::Role::Parameterized::With;

    with Counter => {
        name => 'zapped',
    };

    1;

}

subtest "MyGame::Weapon" => sub {
    my $weapon = MyGame::Weapon->new();

    is $weapon->enchantment, 0, "enchantment attribute must be 0 by default";

    $weapon->increment_enchantment;

    is $weapon->enchantment, 1,
      "enchantment attribute must be 1 after call increment_enchantment";

    done_testing;
};

subtest "MyGame::Wand" => sub {

    my $wand = MyGame::Wand->new( zapped => 8 );

    is $wand->zapped, 8, "zapped attribute must be 8";

    $wand->reset_zapped;

    is $wand->zapped, 0, "zapped attribute must be 0 after call reset_zapped";

    done_testing;
};

subtest "check mandatory parameter" => sub {

    use Test::Exception;
    throws_ok {

        {

            package MyGame::Sword;
            use Moo;
            use MooX::Role::Parameterized::With;

            with Counter => {};

            1;

        }

    }
    qr/unable to apply parameterized role 'Counter' to 'MyGame::Sword': Missing required arguments: name/,
      "must die if add Counter Parameterized role without mandatory parameter 'name'";

    done_testing;
};

subtest "add parametric role without arguments with default parameters" =>
  sub {
    {

        package Some::Class::For::Tests;

        use Moo;
        use MooX::Role::Parameterized::With;

        with 'Some::Parametric::Role::With::Default::Parameters';

        1;
    }

    my $object = Some::Class::For::Tests->new( bar => 1 );

    isa_ok $object, 'Some::Class::For::Tests';

    done_testing;
  };

done_testing;
