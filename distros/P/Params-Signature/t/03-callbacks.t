#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Params::Signature;
use Types::Standard qw(:all);

my $test_count = 0;

our $failed;
our $failed_msg = "";

sub catch_failed
{
    $failed_msg = shift;
    $failed     = 1;
}

my $signature = new Params::Signature(on_fail => \&catch_failed);

Main:
{
    my $test_sub;
    my $test_sub_name;

    diag("Test parameter callbacks, Perl $], $^X");

    foreach $test_sub_name (sort grep /^test_/, keys(%main::))
    {
        $failed     = 0;
        $failed_msg = "";

        # get around "strict refs" when calling subroutine
        $test_sub = \&{"$test_sub_name"};
        &$test_sub($signature, $test_sub_name);
    }
}

# use cases
# 1. 1 callback for 1 field, success
sub test_1_callback_1_field_success
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1],
        ["Int one"],
        {callbacks => {
            one => {
                    "success" => sub { $_[0] == 1 }
            }
        }
        }
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

# 2. 1 callback each for 3 fields, success
sub test_1_callback_each_for_3_fields_success
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1,         2,         3],
        ["Int one", "Int two", "Int three"],
        {callbacks => {
            one => {
                    "success" => sub { $_[0] == 1 }
            },
            two => {
                    "success" => sub { $_[0] == 2 }
            },
            three => {
                      "success" => sub { $_[0] == 3 }
            }
        }
        }
        );
    ok(!$failed && $answer->{one} == 1 && $answer->{two} == 2 && $answer->{three} == 3, "$name: $failed_msg");
}

# 3. 1 callback for 1 field, reject
sub test_1_callback_for_1_field_reject
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1],
        ["Int one"],
        {callbacks => {
            one => {
                    "fail" => sub { $_[0] == 2 }
            }
        }}
        );

    ok($failed && $failed_msg =~ /failed validation via callback 'fail'/, "$name: $failed_msg");
}

# 4. 1 callback each for 3 fields, reject 1 field
sub test_1_callback_each_for_3_fields_reject
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1,         2,         3],
        ["Int one", "Int two", "Int three"],
        {callbacks => {
            one => {
                    "success" => sub { $_[0] == 1 }
            },
            two => {
                    "success" => sub { $_[0] == 2 }
            },
            three => {
                      "fail" => sub { $_[0] == 1 }
            }
        }}
        );
    ok($failed && $failed_msg =~ /failed validation via callback 'fail'/, "$name: $failed_msg");
}

# 5. 3 callback for 1 field, success
sub test_3_callback_for_1_field_success
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1],
        ["Int one"],
        {callbacks => {
            one => {
                    "success 1" => sub { $_[0] == 1 },
                    "success 2" => sub { $_[0] < 2 },
                    "success 3" => sub { $_[0] < 3 }
            }
        }}
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

# 6. 3 callback each for 3 fields, success
sub test_3_callback_each_for_3_fields_success
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1,         2,         3],
        ["Int one", "Int two", "Int three"],
        {callbacks => {
            one => {
                    "success 1.1" => sub { $_[0] == 1 },
                    "success 1.2" => sub { $_[0] < 2 },
                    "success 1.3" => sub { $_[0] < 3 }
            },
            two => {
                    "success 2.1" => sub { $_[0] == 2 },
                    "success 2.2" => sub { $_[0] < 4 },
                    "success 2.3" => sub { $_[0] < 5 }
            },
            three => {
                      "success 3.1" => sub { $_[0] == 3 },
                      "success 3.2" => sub { $_[0] < 4 },
                      "success 3.3" => sub { $_[0] < 5 }
            }
        }}
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

# 7. 3 callback for 1 field, reject
sub test_3_callback_for_1_field_reject
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1],
        ["Int one"],
        {callbacks => {
            one => {
                    "success 1" => sub { $_[0] == 1 },
                    "success 2" => sub { $_[0] < 2 },
                    "fail 3"    => sub { $_[0] < 1 }
            }
        }}
        );

    ok($failed && $failed_msg =~ /failed validation via callback 'fail 3'/, "$name: $failed_msg");
}

# 8. 3 callback each for 3 fields, reject 1 field
sub test_3_callback_each_for_3_fields_reject_1_field
{
    my $signature = shift;
    my $name      = shift;
    my $answer;

    $answer = $signature->validate(
        [1,         2,         3],
        ["Int one", "Int two", "Int three"],
        {callbacks => {
            one => {
                    "success 1.1" => sub { $_[0] == 1 },
                    "success 1.2" => sub { $_[0] < 2 },
                    "success 1.3" => sub { $_[0] < 3 }
            },
            two => {
                    "success 2.1" => sub { $_[0] == 2 },
                    "success 2.2" => sub { $_[0] < 4 },
                    "success 2.3" => sub { $_[0] < 5 }
            },
            three => {
                      "success 3.1" => sub { $_[0] == 3 },
                      "success 3.2" => sub { $_[0] < 4 },
                      "fail 3.3"    => sub { $_[0] < 3 }
            }
        }}
        );

    ok($failed && $failed_msg =~ /failed validation via callback 'fail 3.3'/, "$name: $failed_msg");
}

$test_count += scalar grep /^test_/, keys(%main::);
plan tests => $test_count;
