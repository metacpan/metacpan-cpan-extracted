#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Types::Standard qw(:all);
use Type::Utils qw(declare class_type duck_type role_type as enum as);
use Params::Signature qw(:all);

no warnings qw(once);

my $test_count = 0;

our $failed;
our $failed_msg = "";

sub catch_failed
{
    $failed_msg = shift;
    $failed     = 1;
}


Main:
{
    my $test_sub;
    my $test_sub_name;
    my $signature;

    diag("Test custom type constraint registration and use, Perl $], $^X");

    foreach $test_sub_name (sort grep /^test_/, keys(%main::))
    {
        $failed     = 0;
        $failed_msg = "";
        #diag($test_sub_name);

        $signature = new Params::Signature(param_style => "named", on_fail => \&catch_failed, called => '');
        # clear out cruft left behind by previous test
        Params::Signature->_change_class_default($signature);
        # NOTE: _change_class_default should not be used in applications!

        # get around "strict refs" when calling subroutine
        $test_sub = \&{"$test_sub_name"};
        &$test_sub($signature, $test_sub_name);
    }
}

# use cases
sub test_register_class
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::Params_Signature = class_type "Params_Signature", {class => "Params::Signature"};

    $answer = validate(
        [sig => $signature],
        ["Params_Signature sig"],
	{fuzzy => 2}
        );

    ok(!$failed && $answer->{sig} == $signature, "$name: $failed_msg");
}

sub test_register_role
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::Does_Params_Signature = role_type "Does_Params_Signature", {role => "Params::Signature"};

    $answer = validate(
        [sig => $signature],
        ["Does_Params_Signature sig"],
	{fuzzy => 2}
        );

    ok(!$failed && $answer->{sig} == $signature, "$name: $failed_msg");
}

sub test_register_can
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::CanValidate = duck_type "CanValidate", [qw(validate)];

    $answer = validate(
        [sig => $signature],
        ["CanValidate sig"],
	{fuzzy => 2}
        );

    ok(!$failed && $answer->{sig} == $signature, "$name: $failed_msg");
}

sub test_register_can_invalid
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::CanFoo = duck_type "CanFoo", [qw(foo)];

    $answer = validate(
        [sig => $signature],
        ["CanFoo sig"],
	{fuzzy => 2}
        );

    ok($failed && !$answer->{sig} && $failed_msg =~ /xpected CanFoo/, "$name: $failed_msg");
}

sub test_register_regex
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::IP4 = declare "IP4" => as StrMatch[qr/\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b/];

    $answer = validate(
        [ip => "127.0.0.1"],
        ["IP4 ip"],
	{fuzzy => 2}
        );

    ok(!$failed && $answer->{ip} eq "127.0.0.1", "$name: $failed_msg");
}

sub test_register_regex_invalid
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    #$main::IP4 = declare "IP4" => as StrMatch[qr/\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b/], message => sub { "$_[0]: invalid type of value" };
    $main::IP4 = declare "IP4" => as StrMatch[qr/\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}\b/];

    $answer = validate(
        [ip => "ABC"],
        ["IP4 ip"],
	{fuzzy => 2}
        );

    ok($failed && !$answer->{ip} && $failed_msg =~ /failed validation/, "$name: $failed_msg");
}

sub test_register_enum_multi_values
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    #enum "OneTwoThree", ["1", "2", "3"];
    $main::OneTwoThree = enum "OneTwoThree", [qw(1 2 3)];

    $answer = validate(
        [sig => 2],
        ["OneTwoThree sig"],
	{fuzzy => 2}
        );

    ok(!$failed && $answer->{sig} == 2, "$name: $failed_msg");
}

sub test_register_enum_multi_invalid
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    #enum "OneTwoThree", ["1", "2", "3"];
    $main::OneTwoThree = enum 'OneTwoThree', [qw(1 2 3)];

    $answer = validate(
        [sig => 4],
        ["OneTwoThree sig"],
	{fuzzy => 2}
        );

    ok($failed && !$answer->{sig} && $failed_msg =~ /failed validation/, "$name: $failed_msg");
}

sub test_register_enum_invalid_value
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    $main::Eleven = enum "Eleven", ["11"];

    $answer = validate(
        [sig => "111"],
        ["Eleven sig"],
	{fuzzy => 2}
        );

    ok($failed && !$answer->{sig} && $failed_msg =~ /failed validation/, "$name: $failed_msg");
}

sub test_register_enum_invalid_value2
{
    my $signature = shift;
    my $name = shift;
    my $answer;

    enum "Eleven", ["11"];

    $answer = validate(
        [sig => "1"],
        ["Eleven sig"],
	{fuzzy => 2}
        );

    ok($failed && !$answer->{sig} && $failed_msg =~ /failed validation/, "$name: $failed_msg");
}
$test_count += scalar grep /^test_/, keys(%main::);
plan tests => $test_count;
