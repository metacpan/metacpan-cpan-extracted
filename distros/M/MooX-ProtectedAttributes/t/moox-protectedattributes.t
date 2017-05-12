#!perl
#
# This file is part of MooX-ProtectedAttributes
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use Test::More;

use Test::Trap;

use t::lib::moo::myTestClass;
use t::lib::moo::myTestClass2;
use t::lib::moose::myTestClass;
use t::lib::moose::myTestClass2;

use t::lib::mooWithDeprecated::myTestClass;
use t::lib::mooWithDeprecated::myTestClass2;
use t::lib::mooseWithDeprecated::myTestClass;
use t::lib::mooseWithDeprecated::myTestClass2;

sub run_test {
    my ( $subtest_name, $main_class, $role ) = @_;

    subtest $subtest_name => sub {

        my $t = $main_class->new();

        $t->foo("123");
        $t->bar("456");

        $t->baz("789");  # moo keep the sub instead of replacing it like moose

        eval { $t->foo };
        like $@,
            qr{\QYou can't use the attribute <foo> outside the package <$main_class> or anyone that consume it!\E},
            'reading foo is forbidden';

        {
            local $ENV{SKIP_WARNING} = 1;
            is $t->foo, "123", '... unless we match the "unless" method';
        }

        eval { $t->bar };
        like $@,
            qr{\QYou can't use the attribute <bar> outside the package <$role> or anyone that consume it!\E},
            'reading bar is forbidden';

        eval { $t->baz };
        like $@,
            qr{\QYou can't use the attribute <baz> outside the package <$role> or anyone that consume it!\E},
            'reading baz is forbidden even if redefined';

        is $t->display_role_bar_direct, "DISPLAY: 456",
            "protected bar is accessible inside the the class that consume it";

        is $t->display_foo, "DISPLAY: 123", "foo can be read from main class";
        is $t->display_bar, "DISPLAY: 456", "bar can be read from role class";
        is $t->display_indirect_bar, "DISPLAY: 456",
            "bar can be read from role class by indirect call";
        is $t->display_large_indirect_bar, "DISPLAY: 456",
            "bar can be read from role class by large indirect call";
        is $t->display_baz, "DISPLAY: 789", "baz can be read from role class";
        is $t->display_role_bar, "DISPLAY: 456",
            "bar can be read from role class";
        }
}

sub run_test_with_deprecated {
    my ( $subtest_name, $main_class, $role ) = @_;

    subtest $subtest_name => sub {

        my $t = $main_class->new();

        $t->foo("123");
        $t->bar("456");

        $t->baz("789");  # moo keep the sub instead of replacing it like moose

        trap { is $t->foo(), "123", "we can read foo" };
        like $trap->stderr,
            qr{\QDEPRECATED: You can't use the attribute <foo> outside the package <$main_class> or anyone that consume it!\E},
            '... but we got a deprecated message';

        {
            local $ENV{SKIP_WARNING} = 1;
            trap { is $t->foo(), "123", "we can read foo" };
            ok !$trap->stderr, '... unless we match the "unless" method';
        }

        trap { is $t->bar(), "456", "we can read bar" };
        like $trap->stderr,
            qr{\QDEPRECATED: You can't use the attribute <bar> outside the package <$role> or anyone that consume it!\E},
            '... but we got a deprecated message';

        trap { is $t->baz(), "789", "we can read baz" };
        like $trap->stderr,
            qr{\QDEPRECATED: You can't use the attribute <baz> outside the package <$role> or anyone that consume it!\E},
            '... but we got a deprecated message';

        trap {
            is $t->display_role_bar_direct, "DISPLAY: 456",
                "... also indirectly";
        };
        ok !$trap->stderr,
            '... and we don t have a deprecated message because the protected is allowed inside the class that consume it';

        is $t->display_foo, "DISPLAY: 123", "foo can be read from main class";
        is $t->display_bar, "DISPLAY: 456", "bar can be read from role class";
        is $t->display_indirect_bar, "DISPLAY: 456",
            "bar can be read from role class by indirect call";
        is $t->display_large_indirect_bar, "DISPLAY: 456",
            "bar can be read from role class by large indirect call";
        is $t->display_baz, "DISPLAY: 789", "baz can be read from role class";
        is $t->display_role_bar, "DISPLAY: 456",
            "bar can be read from role class";
        }
}

run_test( 'moo class and direct role',
    't::lib::moo::myTestClass', 't::lib::moo::myTestClassRole' );
run_test( 'moo class and indirect role',
    't::lib::moo::myTestClass2', 't::lib::moo::myTestClassRole3' );
run_test( 'moose class and direct role',
    't::lib::moose::myTestClass', 't::lib::moose::myTestClassRole' );
run_test( 'moose class and indirect role',
    't::lib::moose::myTestClass2', 't::lib::moose::myTestClassRole3' );

run_test_with_deprecated(
    'moo class and direct role (with deprecated)',
    't::lib::mooWithDeprecated::myTestClass',
    't::lib::mooWithDeprecated::myTestClassRole'
);
run_test_with_deprecated(
    'moo class and indirect role (with deprecated)',
    't::lib::mooWithDeprecated::myTestClass2',
    't::lib::mooWithDeprecated::myTestClassRole3'
);
run_test_with_deprecated(
    'moose class and direct role (with deprecated)',
    't::lib::mooseWithDeprecated::myTestClass',
    't::lib::mooseWithDeprecated::myTestClassRole'
);
run_test_with_deprecated(
    'moose class and indirect role (with deprecated)',
    't::lib::mooseWithDeprecated::myTestClass2',
    't::lib::mooseWithDeprecated::myTestClassRole3'
);

done_testing;
