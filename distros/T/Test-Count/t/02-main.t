#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use File::Spec;
use IO::Scalar;

use Test::Count;

{
    open my $in, "<", File::Spec->catfile("t", "sample-data", "test-scripts", "01-parser.t");

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, 5, "Testing for 01-parser.t");

    close($in);
}

{
    open my $in, "<",
        File::Spec->catfile(
            "t", "sample-data", "test-scripts","arithmetics.t"
        );

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, 18, "Testing for arithmetics.t");

    close($in);
}

{
    my $buffer = "# T" . "EST        \n".
    "ok (1, 'Everything is OK');\n";
    my $in = IO::Scalar->new(\$buffer);

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, 1, "Correctly handling trailing whitespace");

    close($in);
}

{
    my $_T = 'T' . 'EST';
    my $buffer = <<"EOF";
use MyModule;

# ${_T}:\$my_func=10;

# ${_T}:\$c=0;

for my \$idx (1 .. 30)
{
    # ${_T}:\$c++;
    ok (1, "Idx \$idx");

    # ${_T}:\$c+=\$my_func;
    MyModule->my_func("Foo", "Foo \$idx");

    # ${_T}:\$c+=\$my_func;
    MyModule->my_bar("Bar", "Bar \$idx");
}

# ${_T}:\$foo_loop=\$c;
# ${_T}*\$foo_loop*30

EOF

    my $in = IO::Scalar->new(\$buffer);

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, (1+10+10)*30,
        "Handling +=.");

    close($in);
}

{
    my $_T = 'T' . 'EST';
    my $buffer = <<"EOF";
use MyModule;

# ${_T}:\$my_func=10;

# ${_T}:\$c=0;

for my \$idx (1 .. 30)
{
    # ${_T}:\$c++;
    ok (1, "Idx \$idx");

    # ${_T}:\$c+=\$my_func+50;
    MyModule->my_func("Foo", "Foo \$idx");

    # ${_T}:\$c-=50;

    # ${_T}:\$c+=\$my_func;
    MyModule->my_bar("Bar", "Bar \$idx");
}

# ${_T}:\$foo_loop=\$c;
# ${_T}*\$foo_loop*30

EOF

    my $in = IO::Scalar->new(\$buffer);

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, (1+10+10)*30,
        "Handling += and -=.");

    close($in);
}

{
    my $_T = 'T' . 'EST';
    my $buffer = <<"EOF";
use MyModule;

# ${_T}:\$my_func=10;

# ${_T}:\$c=0;

for my \$idx (1 .. 30)
{
    # ${_T}:\$c++;
    MyModule->my_func("Foo", "Foo \$idx");

    # ${_T}:\$c++;
    MyModule->my_bar("Bar", "Bar \$idx");
}

# ${_T}:\$c*=\$my_func;
# ${_T}:\$foo_loop=\$c;
# ${_T}*\$foo_loop*30

EOF

    my $in = IO::Scalar->new(\$buffer);

    my $counter = Test::Count->new(
        {
            'input_fh' => $in,
        }
    );

    my $ret = $counter->process();

    # TEST
    is ($ret->{'tests_count'}, (10+10)*30,
        "Handling *=",);

    close($in);
}
