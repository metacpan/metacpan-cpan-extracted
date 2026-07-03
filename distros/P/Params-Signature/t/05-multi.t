#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Standard qw(:all);
use Params::Signature;
use Params::Signature::Multi;

my $test_count = 0;

our $failed;
our $failed_msg = "";

sub catch_failed
{
    $failed_msg = shift || "";
    $failed     = 1;
}

my $multi = new Params::Signature::Multi(on_fail => \&catch_failed);

# cheating ... probably shouldn't do this in a real program
Params::Signature::Multi->class_default->{on_fail} = \&catch_failed;

Main:
{
    my $test_sub;
    my $test_sub_name;

    diag("Test multi dispatch, Perl $], $^X");

    foreach $test_sub_name (sort grep /^test_/, keys(%main::))
    {
        $failed     = 0;
        $failed_msg = "";

        # get around "strict refs" when calling subroutine
        $test_sub = \&{"$test_sub_name"};
        &$test_sub($multi, $test_sub_name);
    }
}

# use cases
sub test_resolve_2_signatures_1_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]}
        ]
        );

    ok(!$failed && $answer eq "two", "$name: $answer, $failed, $failed_msg");
}

sub test_resolve_3_signatures_2_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok(!$failed && $answer eq "two", "$name: $answer, $failed, $failed_msg");
}

sub test_resolve_3_signatures_0_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, "hi"],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok($failed && $answer == -1, "$name: $answer, $failed, $failed_msg");
}

sub dispatch_ok
{
    "dispatch_ok";
}

sub dispatch_not_ok
{
    "dispatch_not_ok";
}

sub test_dispatch_2_signatures_1_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_ok}
        ]
        );

    ok(!$failed && $answer eq "dispatch_ok", "$name: $answer, $failed, $failed_msg");
}

sub test_dispatch_3_signatures_2_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_ok},
            { id => "three", signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );

    ok(!$failed && $answer eq "dispatch_ok", "$name: $answer, $failed, $failed_msg");
}

sub test_dispatch_3_signatures_0_match
{
    my $multi = shift;
    my $name = shift;
    my $answer = "";

    $answer = $multi->dispatch(
        [1, "hi"],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_not_ok},
            { id => "three", signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );
    $answer = (!defined($answer)) ? 'undef' : $answer;

    ok($failed, "$name: $answer, $failed, $failed_msg");
}

sub test_dispatch_3_signatures_missing_call
{
    my $multi = shift;
    my $name = shift;
    my $answer = "";

    $answer = $multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]},
        ]
        );
    $answer = (!defined($answer)) ? 'undef' : $answer;

    ok($failed && $failed_msg =~ /no subroutine/i, "$name: $answer, $failed, $failed_msg");
}

sub test_class_resolve_2_signatures_1_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->resolve(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]}
        ]
        );

    ok(!$failed && $answer eq "two", "$name: $answer, $failed, $failed_msg");
}

sub test_class_resolve_3_signatures_2_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->resolve(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok(!$failed && $answer eq "two", "$name: $answer, $failed, $failed_msg");
}

sub test_class_resolve_3_signatures_0_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->resolve(
        [1, "hi"],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok($failed && $answer == -1, "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_2_signatures_1_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_ok}
        ]
        );

    ok(!$failed && $answer eq "dispatch_ok", "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_3_signatures_2_match
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_ok},
            { id => "three", signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );

    ok(!$failed && $answer eq "dispatch_ok", "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_3_signatures_0_match
{
    my $multi = shift;
    my $name = shift;
    my $answer = "";

    $answer = Params::Signature::Multi->dispatch(
        [1, "hi"],
        [
            { id => "one", signature => ["Int one"], call => \&dispatch_not_ok},
            { id => "two", signature => ["Int one", "Int two"], call => \&dispatch_not_ok},
            { id => "three", signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );
    $answer = (!defined($answer)) ? 'undef' : $answer;

    ok($failed, "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_3_signatures_missing_call
{
    my $multi = shift;
    my $name = shift;
    my $answer = "";

    $answer = Params::Signature::Multi->dispatch(
        [1, 2],
        [
            { id => "one", signature => ["Int one"]},
            { id => "two", signature => ["Int one", "Int two"]},
            { id => "three", signature => ["Int one", "Int two", "Int three?"]},
        ]
        );
    $answer = (!defined($answer)) ? 'undef' : $answer;

    ok($failed && $failed_msg =~ /no subroutine/i, "$name: $answer, $failed, $failed_msg");
}

sub test_resolve_2_signatures_1_match_unnamed
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, 2],
        [
            { signature => ["Int one"]},
            { signature => ["Int one", "Int two"]}
        ]
        );

    ok(!$failed && $answer == 1, "$name: $answer, $failed, $failed_msg");
}

sub test_resolve_3_signatures_2_match_unnamed
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, 2],
        [
            { signature => ["Int one"]},
            { signature => ["Int one", "Int two"]},
            { signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok(!$failed && $answer == 1, "$name: $answer, $failed, $failed_msg");
}

sub test_resolve_3_signatures_0_match_unnamed
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = $multi->resolve(
        [1, "hi"],
        [
            { signature => ["Int one"]},
            { signature => ["Int one", "Int two"]},
            { signature => ["Int one", "Int two", "Int three?"]}
        ]
        );

    ok($failed && $answer == -1, "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_3_signatures_2_match_unnamed
{
    my $multi = shift;
    my $name = shift;
    my $answer;

    $answer = Params::Signature::Multi->dispatch(
        [1, 2],
        [
            { signature => ["Int one"], call => \&dispatch_not_ok},
            { signature => ["Int one", "Int two"], call => \&dispatch_ok},
            { signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );

    ok(!$failed && $answer eq "dispatch_ok", "$name: $answer, $failed, $failed_msg");
}

sub test_class_dispatch_3_signatures_0_match_unnamed
{
    my $multi = shift;
    my $name = shift;
    my $answer = "";

    $answer = Params::Signature::Multi->dispatch(
        [1, "hi"],
        [
            { signature => ["Int one"], call => \&dispatch_not_ok},
            { signature => ["Int one", "Int two"], call => \&dispatch_not_ok},
            { signature => ["Int one", "Int two", "Int three?"], call => \&dispatch_not_ok}
        ]
        );
    $answer = (!defined($answer)) ? 'undef' : $answer;

    ok($failed, "$name: $answer, $failed, $failed_msg");
}


$test_count += scalar grep /^test_/, keys(%main::);
plan tests => $test_count;
