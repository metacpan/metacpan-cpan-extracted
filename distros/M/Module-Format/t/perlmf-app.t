
use strict;
use warnings;

use Test::More;
use Module::Format::PerlMF_App;

use vars qw($trap);

eval q{use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );};

if ($@)
{
    plan skip_all => "Test::Trap not found.";
}

plan tests => 6;

# TEST
ok(1, "Test is OK.");

{
    trap(sub {
        Module::Format::PerlMF_App->new(
            {
                argv => [qw/as_rpm_colon Data::Dump XML-Grammar-Fortune/],
            },
        )->run();
    });

    # TEST
    is (
        $trap->stdout(),
        qq{perl(Data::Dump) perl(XML::Grammar::Fortune)\n},
        'as_rpm_colon works as expected.',
    );
}

{
    trap(sub {
        Module::Format::PerlMF_App->new(
            {
                argv => [qw/as_colon Data::Dump XML-Grammar-Fortune/],
            },
        )->run();
    });

    # TEST
    is (
        $trap->stdout(),
        qq{Data::Dump XML::Grammar::Fortune\n},
        'as_colon works as expected.',
    );
}

{
    trap(sub {
        Module::Format::PerlMF_App->new(
            {
                argv => [qw/deb Foo::Bar::Baz Quux-Stanley/],
            },
        )->run();
    });

    # TEST
    is (
        $trap->stdout(),
        qq{libfoo-bar-baz-perl libquux-stanley-perl\n},
        'deb works as expected.',
    );
}

{
    trap(sub {
        Module::Format::PerlMF_App->new(
            {
                argv => [qw/as_rpm_colon -0 Data::Dump XML-Grammar-Fortune/],
            },
        )->run();
    });

    # TEST
    is (
        $trap->stdout(),
        qq{perl(Data::Dump)\0perl(XML::Grammar::Fortune)},
        'as_rpm_colon -0 works as expected.',
    );
}

{
    trap(sub {
        Module::Format::PerlMF_App->new(
            {
                argv => [qw/as_rpm_colon -n Data::Dump XML-Grammar-Fortune/],
            },
        )->run();
    });

    # TEST
    is (
        $trap->stdout(),
        qq{perl(Data::Dump)\nperl(XML::Grammar::Fortune)\n},
        '-n works as expected.',
    );
}
