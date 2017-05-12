#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLibrary qw( NonEmptyStr IntArrayRef ),
                Foo2Alias => { -as => 'Foo' };

my @tests = (
    [ 'NonEmptyStr', 12, "12", [], "foobar", "" ],
    [ 'IntArrayRef', 12, [12], {}, [17, 23], {} ],
);

plan tests => (@tests * 8) + 5;

# new array ref so we can safely shift from it
for my $data (map { [@$_] } @tests) {
    my $type = shift @$data;

    # Type name export
    {
        ok my $code = __PACKAGE__->can($type), "$type() was exported";
        is $code->(), "TestLibrary::$type", "$type() returned correct type name";
    }

    # coercion handler export
    {   
        my ($coerce, $coercion_result, $cannot_coerce) = map { shift @$data } 1 .. 3;
        ok my $code = __PACKAGE__->can("to_$type"), "to_$type() coercion was exported";
        is_deeply scalar $code->($coerce), $coercion_result, "to_$type() coercion works";
        ok ! $code->($cannot_coerce), "to_$type() returns false on invalid value";
    }

    # type test handler
    {
        my ($valid, $invalid) = map { shift @$data } 1 .. 2;
        ok my $code = __PACKAGE__->can("is_$type"), "is_$type() check was exported";
        ok $code->($valid), "is_$type() check true on valid value";
        ok ! $code->($invalid), "is_$type() check false on invalid value";
    }
}

# aliasing test
ok my $code = __PACKAGE__->can('Foo'),      'aliased type exported under correct symbol';
is $code->(), 'TestLibrary::Foo2Alias',     'aliased type returns unaliased type name';

# coercion not available
ok ! __PACKAGE__->can('to_TwentyThree'), "type without coercion doesn't have to_* helper";

eval { require TestNamespaceSep };
ok   $@,                q(trying to declare a type with '::' in it croaks);
like $@, qr/Foo::Bar/,  q(error message contains type name);
