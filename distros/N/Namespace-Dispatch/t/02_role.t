use Modern::Perl;
use Test::More;
use Try::Tiny;

use lib qw(lib t/lib);

SKIP: {
    eval { require Moose };

    if ($@) {
        skip "Moose not installed", 4;
    } else {
        require Foo::Class;
        require Foo::ClassWithRole;
    }

    is (
        ref(Namespace::Dispatch->meta),
        "Moose::Meta::Role",
        "Namespace::Dispatch is a Moose::Role",
    );

    ok (
        Foo::Class->does("Namespace::Dispatch"),
        "Foo::Class does Namespace::Dispatch",
    );

    ok (
        Foo::Role->meta->does_role("Namespace::Dispatch"),
        "Foo::Role does Namespace::Dispatch",
    );

    ok (
        Foo::ClassWithRole->does("Namespace::Dispatch"),
        "Foo::ClassWithRole does Namespace::Dispatch",
    );

}

done_testing;
