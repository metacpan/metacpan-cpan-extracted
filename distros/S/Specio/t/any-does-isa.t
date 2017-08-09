use strict;
use warnings;
use utf8;
use open ':encoding(UTF-8)', ':std';

use Test::Fatal;
use Test::More 0.96;

use Specio::Declare;

## no critic (Modules::ProhibitMultiplePackages)
{
    package Foo;
    sub quux { }
}

subtest(
    'object_can_type',
    sub {
        my $object_can = object_can_type( methods => [ 'foo', 'bar' ] );
        like(
            exception { $object_can->validate_or_die(undef) },
            qr/\QAn undef will never pass an ObjectCan check (wants bar and foo)/,
            'exception for undef'
        );
        like(
            exception { $object_can->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an ObjectCan check (wants bar and foo)/,
            'exception for empty string'
        );
        like(
            exception { $object_can->validate_or_die('Foo') },
            qr/\QA plain scalar ("Foo") will never pass an ObjectCan check (wants bar and foo)/,
            'exception for non-empty string'
        );
        like(
            exception { $object_can->validate_or_die(42) },
            qr/\QA number (42) will never pass an ObjectCan check (wants bar and foo)/,
            'exception for number'
        );
        like(
            exception { $object_can->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an ObjectCan check (wants bar and foo)/,
            'exception for arrayref'
        );
        like(
            exception { $object_can->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class is missing the 'bar' and 'foo' methods/,
            'exception for object without wanted methods'
        );
    }
);

subtest(
    'any_can_type',
    sub {
        my $any_can = any_can_type( methods => [ 'foo', 'bar' ] );
        like(
            exception { $any_can->validate_or_die(undef) },
            qr/\QAn undef will never pass an AnyCan check (wants bar and foo)/,
            'exception for undef'
        );
        like(
            exception { $any_can->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an AnyCan check (wants bar and foo)/,
            'exception for empty string'
        );
        like(
            exception { $any_can->validate_or_die('Baz') },
            qr/\QThe Baz class is missing the 'bar' and 'foo' methods/,
            'exception for non-empty string'
        );
        like(
            exception { $any_can->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an AnyCan check (wants bar and foo)/,
            'exception for arrayref'
        );
        like(
            exception { $any_can->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class is missing the 'bar' and 'foo' methods/,
            'exception for non-empty string'
        );
    }
);

subtest(
    'object_isa_type',
    sub {
        my $object_isa = object_isa_type( class => 'Foo' );
        like(
            exception { $object_isa->validate_or_die(undef) },
            qr/\QAn undef will never pass an ObjectIsa check (wants Foo)/,
            'exception for undef'
        );
        like(
            exception { $object_isa->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an ObjectIsa check (wants Foo)/,
            'exception for empty string'
        );
        like(
            exception { $object_isa->validate_or_die('Foo') },
            qr/\QA plain scalar ("Foo") will never pass an ObjectIsa check (wants Foo)/,
            'exception for non-empty string'
        );
        like(
            exception { $object_isa->validate_or_die(42) },
            qr/\QA number (42) will never pass an ObjectIsa check (wants Foo)/,
            'exception for number'
        );
        like(
            exception { $object_isa->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an ObjectIsa check (wants Foo)/,
            'exception for arrayref'
        );
        like(
            exception { $object_isa->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class is not a subclass of the Foo class/,
            'exception for object of the wrong class'
        );
    }
);

subtest(
    'any_isa_type',
    sub {
        my $any_isa = any_isa_type( class => 'Foo' );
        like(
            exception { $any_isa->validate_or_die(undef) },
            qr/\QAn undef will never pass an AnyIsa check (wants Foo)/,
            'exception for undef'
        );
        like(
            exception { $any_isa->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an AnyIsa check (wants Foo)/,
            'exception for empty string'
        );
        like(
            exception { $any_isa->validate_or_die('Baz') },
            qr/\QThe Baz class is not a subclass of the Foo class/,
            'exception for plain scalar'
        );
        like(
            exception { $any_isa->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an AnyIsa check (wants Foo)/,
            'exception for arrayref'
        );
        like(
            exception { $any_isa->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class is not a subclass of the Foo class/,
            'exception for object of the wrong class'
        );
    }
);

{
    package Role::Foo;
    use Role::Tiny;
}

subtest(
    'object_does_type',
    sub {
        my $object_does = object_does_type( role => 'Role::Foo' );
        like(
            exception { $object_does->validate_or_die(undef) },
            qr/\QAn undef will never pass an ObjectDoes check (wants Role::Foo)/,
            'exception for undef'
        );
        like(
            exception { $object_does->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an ObjectDoes check (wants Role::Foo)/,
            'exception for empty string'
        );
        like(
            exception { $object_does->validate_or_die('Role::Foo') },
            qr/\QA plain scalar ("Role::Foo") will never pass an ObjectDoes check (wants Role::Foo)/,
            'exception for non-empty string'
        );
        like(
            exception { $object_does->validate_or_die(42) },
            qr/\QA number (42) will never pass an ObjectDoes check (wants Role::Foo)/,
            'exception for number'
        );
        like(
            exception { $object_does->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an ObjectDoes check (wants Role::Foo)/,
            'exception for arrayref'
        );
        like(
            exception { $object_does->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class does not consume the Role::Foo role/,
            'exception for object that does not consume the wanted role'
        );
    }
);

subtest(
    'any_does_type',
    sub {
        my $any_does = any_does_type( role => 'Role::Foo' );
        like(
            exception { $any_does->validate_or_die(undef) },
            qr/\QAn undef will never pass an AnyDoes check (wants Role::Foo)/,
            'exception for undef'
        );
        like(
            exception { $any_does->validate_or_die(q{}) },
            qr/\QAn empty string will never pass an AnyDoes check (wants Role::Foo)/,
            'exception for empty string'
        );
        like(
            exception { $any_does->validate_or_die('Baz') },
            qr/\QThe Baz class does not consume the Role::Foo role/,
            'exception for plain scalar'
        );
        like(
            exception { $any_does->validate_or_die( [] ) },
            qr/\QAn unblessed reference ([  ]) will never pass an AnyDoes check (wants Role::Foo)/,
            'exception for arrayref'
        );
        like(
            exception { $any_does->validate_or_die( bless {}, 'Baz' ) },
            qr/\QThe Baz class does not consume the Role::Foo role/,
            'exception for object that does not consume the wanted role'
        );
    }
);

done_testing();
