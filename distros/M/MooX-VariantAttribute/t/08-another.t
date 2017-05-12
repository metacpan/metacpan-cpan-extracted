use Test::More;

use lib '.';

use t::odea::Test;

my $attribute = t::odea::Test->new( string => 'one' );

is $attribute->string, 'one - cold, cold, cold inside';

ok($attribute->string('two'));

is $attribute->string, 'two - don\'t look at me that way';

ok($attribute->string('three'));

is $attribute->string, 'three - how hard will i fall if I live a double life';

ok($attribute->refs($attribute->string));

is $attribute->refs, 'refs returned - SCALAR - three - how hard will i fall if I live a double life';

{
    package Backwards::World;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
    );
}

my $object = Backwards::World->new( );

is $object->hello({ one => 'two' }), 'one';
is $object->hello, 'one';

is $object->hello({ three => 'four' }), 'four';
is $object->hello, 'four';

is $object->hello([ qw/five six/ ]), 'six';
is $object->hello, 'six';

is $object->hello('seven'), 'one';
is $object->hello, 'one';

{
    package Backwards::World::Goodbye;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant goodbye => (
        given => Any,
        when => [
            { one => 'two' } => {
                alias => {
                    three => 'one',
                }
            },
        ],
    );

}

my $object2 = Backwards::World::Goodbye->new( goodbye => { one => 'two' } );
is_deeply $object2->goodbye, { one => 'two', three => 'two' };

{
    package Backwards::World::Default;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
        default => 'seven',
    );
}

my $object3 = Backwards::World::Default->new();
is $object3->hello, 'one';

{
    package Backwards::World::DefaultHash;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
        default => { three => 'four' },
    );
}

my $object4 = Backwards::World::DefaultHash->new();
is $object4->hello, 'four';

{
    package Backwards::World::DefaultHashSub;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
        default => sub { { three => 'four' } },
    );
}

my $object5 = Backwards::World::DefaultHashSub->new();
is $object5->hello, 'four';


{
    package Backwards::World::Builder;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
        builder => 1,
    );

    sub _build_hello {
        return { one => 'two' };
    }
}

my $object5 = Backwards::World::Builder->new();
is $object5->hello, 'one';

{
    package Backwards::World::Lazy;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => sub { return keys %{ $_[2] } },
            },
            { three => 'four' } => {
                run => sub { return values %{ $_[2] } },
            },
            [ qw/five six/ ] => {
                run => sub { return $_[2]->[1] },
            },
            seven => {
                run => sub { return $_[0]->hello({ one => 'two' }) },
            }
        ],
        builder => 1,
        lazy => 1,
    );

    sub _build_hello {
        return { one => 'two' };
    }
}

my $object5 = Backwards::World::Lazy->new();
is $object5->hello, 'one';

{
    package Backwards::World::Subs;
    use Moo;
    use MooX::VariantAttribute;
    use Types::Standard qw/Any/;

    variant hello => (
        given => Any,
        when => [
            { one => 'two' } => {
                run => 'one',
            },
            { three => 'four' } => {
                run => 'two',
            },
            [ qw/five six/ ] => {
                run => 'three',
            },
            seven => {
                run => 'four',
            }
        ],
        builder => 1,
    );

    sub _build_hello {
        return { one => 'two' };
    }

    sub one {
        return 'one';
    }

    sub two {
        return 'two';
    }
    
    sub three {
        return 'three';
    }

    sub four {
        return $_[0]->hello({ one => 'two' });
    }

}

my $object6 = Backwards::World::Subs->new();
is $object6->hello, 'one';

is $object6->hello({ three => 'four' }), 'two';
is $object6->hello, 'two';

is $object6->hello([ qw/five six/ ]), 'three';
is $object6->hello, 'three';

is $object6->hello('seven'), 'one';
is $object6->hello, 'one';

done_testing();
