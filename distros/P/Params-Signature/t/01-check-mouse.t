#!perl 
use 5.006;
use strict;
use Test::More;
use Test::Requires { Mouse => 1.00 };
use FileHandle;
my $fh = new FileHandle;
use Params::Signature;
my $signature = new Params::Signature(on_fail => sub { });
use Mouse::Util::TypeConstraints;

no warnings;

# some vars below used 1x, so suppress warning
my @type_tests = (
    ["ArrayRef" => {value => [0, 1], ok => 1}],
    ["ArrayRef" => {value => {},             ok => 0}],
    #["ArrayRef" => {value => new FileHandle, ok => 0}],
    ["ArrayRef" => {value => $fh, ok => 0}],
    ["ArrayRef" => {value => *STDERR,        ok => 0}],

    ["Bool" => {value => "0",      ok => 1}],
    ["Bool" => {value => "123.45", ok => 0}],
    ["Bool" => {value => "1",      ok => 1}],
    ["Bool" => {value => "hi",     ok => 0}],
    ["Bool" => {value => "",       ok => 1}],
    ["Bool" => {value => undef,    ok => 1}],

    ["CodeRef" => {value => "hi", ok => 0}],
    ["CodeRef" => {value => sub { 1 }, ok => 1}],

    ["FileHandle" => {value => "main",         ok => 0}],
    #["FileHandle" => {value => new FileHandle, ok => 1}],
    ["FileHandle" => {value => $fh, ok => 1}],
    # this test only works with Mouse, not sure why
    ["FileHandle" => {value => *STDERR,        ok => 1}],

    ["GlobRef" => {value => *main{GLOB},    ok => 1}],
    #["GlobRef" => {value => new FileHandle, ok => 0}],
    ["GlobRef" => {value => $fh, ok => 0}],
    ["GlobRef" => {value => *fh{GLOB},      ok => 1}],
    ["GlobRef" => {value => *STDERR,        ok => 0}],

    ["HashRef" => {value => [0, 1], ok => 0}],
    #["HashRef" => {value => new FileHandle, ok => 0}],
    ["HashRef" => {value => $fh, ok => 0}],
    ["HashRef" => {value => {},             ok => 1}],

    ["Int" => {value => "123.45", ok => 0}],
    ["Int" => {value => "123",    ok => 1}],
    ["Int" => {value => 123,      ok => 1}],
    ["Int" => {value => "hi",     ok => 0}],

    ["Num" => {value => "123.45", ok => 1}],
    ["Num" => {value => 123.45,   ok => 1}],
    ["Num" => {value => "hi",     ok => 0}],
    ["Num" => {value => "1",      ok => 1}],
    ["Num" => {value => 1,        ok => 1}],

    ["ClassName" => {value => "Foo",               ok => 0}],
    ["ClassName" => {value => "main",              ok => 1}],
    ["ClassName" => {value => "Params::Signature", ok => 1}],

    ["Object" => {value => $signature,              ok => 1}],
    ["Object" => {value => new Params::Signature(), ok => 1}],
    ["Object" => {value => "1",                     ok => 0}],
    ["Object" => {value => sub { 1 }, ok => 0}],

    ["Str" => {value => "hi",           ok => 1}],
    ["Str" => {value => undef,          ok => 0}],
    ["Str" => {value => 123,            ok => 1}],
    #["Str" => {value => new FileHandle, ok => 0}],
    ["Str" => {value => $fh, ok => 0}],

    ["Undef" => {value => "hi",  ok => 0}],
    ["Undef" => {value => "",    ok => 0}],
    ["Undef" => {value => undef, ok => 1}],

    ["Value" => {value => "123.45", ok => 1}],
    ["Value" => {value => 123.45,   ok => 1}],
    ["Value" => {value => "1",      ok => 1}],
    ["Value" => {value => 1,        ok => 1}],
    ["Value" => {value => "hi",     ok => 1}],
    ["Value" => {value => sub { 1 }, ok => 0}],

    );

use warnings;

plan tests => scalar @type_tests;

Main:
{
    my $type_name;
    my $type_test;
    my $test_arg;
    my $answer;
    my $msg;
    my $tc;

    diag("Perform type check tests, Perl $], $^X");

    foreach $type_test (@type_tests)
    {
        $type_name = $type_test->[0];
        $test_arg  = $type_test->[1];
        ($answer, $msg, $tc) = $signature->check($type_name, $test_arg->{value});

        # some tests use undef as a value, so turn off warnings
        no warnings;
        ok($answer == $test_arg->{ok}, "$type_name: check '$test_arg->{value}', $msg, $tc");
    }

};

