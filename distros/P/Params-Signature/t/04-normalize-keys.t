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

my $signature = new Params::Signature(param_style => "named", on_fail => \&catch_failed);

Main:
{
    my $test_sub;
    my $test_sub_name;

    diag("Test parameter normalize_keys callback, Perl $], $^X");

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
sub test_1_field_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $answer = $signature->validate(
         [{-one => 1}],
         ["Int one"],
         {normalize_keys => 
                    sub { $_[0] =~ s/^-//; $_[0]; }
        }
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

sub test_3_field_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $answer = $signature->validate(
        [{-one => 1, -two => 2, -THREE => 3}],
        ["Int one", "Int two", "Int three"],
        { normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
                }
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

sub test_3_field_1_with_no_change_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $answer = $signature->validate(
        [{-ONE => 1, -TWO => 2, three => 3}],
        ["Int one", "Int two", "Int three"],
        { normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
            }
        );

    ok(!$failed && $answer->{one} == 1, "$name: $failed_msg");
}

sub test_3_field_3_with_no_change_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $answer = $signature->validate(
        [{one => 1, two => 2, three => 3}],
        ["Int one", "Int two", "Int three"],
        { normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
        }
        );

    ok(!$failed && $answer->{one} == 1 && $answer->{two} == 2 && $answer->{three} == 3, "$name: $failed_msg");
}

sub test_normalize_for_fuzzy_test_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $signature = new Params::Signature(param_style => "positional", on_fail => \&catch_failed);

    $answer = $signature->validate(
        [{-ONE => 1, -TWO => 2}],
        ["Int one", "Int two", "Int three?"],
        { fuzzy => 1,
        normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
                }
        );

    ok(!$failed && $answer->{one} == 1 && $answer->{two} == 2, "$name: $failed_msg");
}

sub test_normalize_for_fuzzy_test_fail
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $signature = new Params::Signature(param_style => "positional", on_fail => \&catch_failed);

    # this will fail because fuzzy tests will not detect that this
    # is a named set of params since only 2 of 3 required parameters
    # are actually present
    $answer = $signature->validate(
        [{-ONE => 1, -TWO => 2}],
        ["Int one", "Int two", "Int three"],
        { fuzzy => 1,
        normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
                }
        );

    ok($failed, "$name: $failed_msg");
}

sub test_normalize_for_fuzzy_test_extra_params_success
{
    my $signature = shift;
    my $name = shift;;
    my $answer;

    $signature = new Params::Signature(param_style => "positional", on_fail => \&catch_failed);

    $answer = $signature->validate(
        [{-ONE => 1, -TWO => 2, -THREE => 3}],
        ["Int one", "Int two", "..."],
        { fuzzy => 1,
        normalize_keys => 
                    sub { $_[0] =~ s/^-//; lc $_[0]; }
                }
        );

    ok(!$failed && $answer->{one} == 1 && $answer->{two} == 2 && $answer->{three} == 3, "$name: $failed_msg");
}

$test_count += scalar grep /^test_/, keys(%main::);
plan tests => $test_count;
