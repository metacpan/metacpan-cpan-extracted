#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my @cases = (
    {
        name                  => "Simple check",
        expected_return_value => 6,
        expected_output       => <<"OUTPUT",
--> MyPackage::Func1
--> MyPackage::Func2
--> MyPackage::Func3
OUTPUT
        action => sub {

            package MyPackage;

            sub Func1 { 1 }
            sub Func2 { 2 }
            sub Func3 { 3 }

            use Subs::Trace;

            Func1() + Func2() + Func3();
        },
    },
    {
        name                  => "Simple check - run again",
        expected_return_value => 4,
        expected_output       => <<"OUTPUT",
--> MyPackage2::Func1
--> MyPackage2::Func3
OUTPUT
        action => sub {

            package MyPackage2;

            sub Func1 { 1 }
            sub Func2 { 2 }
            sub Func3 { 3 }

            use Subs::Trace;

            Func1() + Func3();
        },
    },
);

for my $case ( @cases ) {

    # Capture output.
    my $output       = "";
    my $return_value = "";
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$output or die $!;
        open STDERR, ">>", \$output or die $!;
        $return_value = eval { $case->{action}->() };
        if ( $@ ) {
            $output = $@;
            chomp $output;
        }
    }

    # Check if we are getting output.
    is( $output, $case->{expected_output}, "$case->{name} - output", );

    # Check if the functions still return the correct values.
    is(
        $return_value,
        $case->{expected_return_value},
        "$case->{name} - return_value",
    );
}

done_testing();

