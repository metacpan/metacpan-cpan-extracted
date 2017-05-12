#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Mouse::Util::TypeConstraints;
BEGIN { coerce 'Str', from 'Int', via { "$_" } }
use TestWrapper TestLibrary => [qw( NonEmptyStr IntArrayRef )],
                Mouse       => [qw( Str Int )];


my @tests = (
    [ 'NonEmptyStr', 'TestLibrary::NonEmptyStr', 12, "12", [], "foobar", "" ],
    [ 'IntArrayRef', 'TestLibrary::IntArrayRef', 12, [12], {}, [17, 23], {} ],
    [ 'Str',         'Str',                      12, "12", [], "foo", [777] ],
);

plan tests => (@tests * 9);

# new array ref so we can safely shift from it
for my $data (map { [@$_] } @tests) {
    my $type = shift @$data;
    my $full = shift @$data;

    # Type name export
    {
        ok my $code = __PACKAGE__->can($type), "$type() was exported";
        is $code->(), $full, "$type() returned correct type name";
    }

    # coercion handler export
    {   
        my ($coerce, $coercion_result, $cannot_coerce) = map { shift @$data } 1 .. 3;
        ok my $code = __PACKAGE__->can("to_$type"), "to_$type() coercion was exported";
        is_deeply scalar $code->($coerce), $coercion_result, "to_$type() coercion works";
        eval { $code->($cannot_coerce) };
        is $@, "coercion returned undef\n", "to_$type() died on invalid value";
    }

    # type test handler
    {
        my ($valid, $invalid) = map { shift @$data } 1 .. 2;
        ok my $code = __PACKAGE__->can("is_$type"), "is_$type() check was exported";
        ok $code->($valid), "is_$type() check true on valid value";
        ok ! $code->($invalid), "is_$type() check false on invalid value";
        is ref($code->()), 'CODE', "is_$type() returns test closure without args";
    }
}


