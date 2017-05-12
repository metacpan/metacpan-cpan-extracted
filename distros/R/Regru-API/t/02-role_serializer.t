use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;

{
    # role consumer
    package Foo::Bar;

    use strict;
    use Moo;

    with 'Regru::API::Role::Serializer';

    1;
}

subtest 'Serializer role' => sub {
    plan tests => 5;

    my $foo = new_ok 'Foo::Bar';

    isa_ok $foo, 'Foo::Bar';
    can_ok $foo, 'serializer';

    ok $foo->does('Regru::API::Role::Serializer'), 'Instance does the Serializer role';

    my $json = $foo->serializer;

    isa_ok(
        $json,
        'JSON',
        'serializer',
    );
};

subtest 'Bogus serializer' => sub {
    plan tests => 3;

    # wtf-serializer
    my $bogus = bless { -answer => 42 }, 'Bogus::Serializer';

    my $foo;

    like(
        exception { $foo = Foo::Bar->new(serializer => $bogus) },
        qr/is not a JSON instance/,
        'catch exception thrown on create object',
    );

    # use defaults
    $foo = new_ok 'Foo::Bar';

    like(
        exception { $foo->serializer($bogus) },
        qr/is not a JSON instance/,
        'catch exception thrown on change attribute',
    );
};

subtest 'Serializer can not encode/decode' => sub {
    plan tests => 6;

    # wtf-serializer
    my $bogus = bless { -answer => 42 }, 'Bogus::JSON';

    my $foo;

    like(
        exception { $foo = Foo::Bar->new(serializer => $bogus) },
        qr/can not decode/,
        'catch exception thrown on create object',
    );

    # use defaults
    $foo = new_ok 'Foo::Bar';

    like(
        exception { $foo->serializer($bogus) },
        qr/can not decode/,
        'catch exception thrown on change attribute',
    );

    {
        no warnings 'once';
        *Bogus::JSON::decode = sub { 1 };
    };

    like(
        exception { $foo = Foo::Bar->new(serializer => $bogus) },
        qr/can not encode/,
        'catch exception thrown on create object',
    );

    # use defaults
    $foo = new_ok 'Foo::Bar';

    like(
        exception { $foo->serializer($bogus) },
        qr/can not encode/,
        'catch exception thrown on change attribute',
    );
};

subtest 'Github issue #5 (support_by_pp)' => sub {
    plan tests => 4;

    {
        package Fake::Dancer::Serializer::Factory;

        require JSON;

        JSON->unimport();
        JSON->import( '-support_by_pp' );

        sub instance { JSON->new->utf8; }

        1;
    };

    my $instance = Fake::Dancer::Serializer::Factory->instance();

    my $foo;

    isa_ok(
        $instance,
        'JSON::Backend::XS::Supportable',
        'instance',
    );

    is(
        exception { $foo = Foo::Bar->new(serializer => $instance) },
        undef,
        'set serializer as constructor param',
    );

    # use defaults
    $foo = new_ok 'Foo::Bar';

    is(
        exception { $foo->serializer($instance) },
        undef,
        'set serializer by attribute',
    );
};

1;
