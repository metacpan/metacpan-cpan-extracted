use strict;
use warnings;
use utf8;
use open ':encoding(UTF-8)', ':std';

use Test::More 0.96;

use Specio::Declare;
use Specio::Library::Builtins;
use Specio::PartialDump qw( partial_dump );

{
    my $str = t('Str');
    isa_ok( $str, 'Specio::Constraint::Simple' );
    like(
        $str->declared_at->filename,
        qr/Builtins\.pm/,
        'declared_at has the right filename'
    );

    for my $value ( q{}, 'foo', 'bar::baz', "\x{3456}", 0, 42 ) {
        ok(
            $str->value_is_valid($value),
            partial_dump($value) . ' is a valid Str value'
        );
    }

    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'once';
    ## use critic
    my $foo = 'foo';
    for my $value ( undef, \42, \$foo, [], {}, sub { }, *glob, \*globref ) {
        ok(
            !$str->value_is_valid($value),
            partial_dump($value) . ' is not a valid Str value'
        );
    }
}

is(
    t('Str')->parent->name,
    'Value',
    'parent of Str is Value'
);

my $str_clone = t('Str')->clone;

for my $name (qw( Str Value Defined Item )) {
    ok(
        t('Str')->is_a_type_of( t($name) ),
        "Str is_a_type_of($name)"
    );

    next if $name eq 'Str';

    ok(
        $str_clone->is_a_type_of( t($name) ),
        "Str clone is_a_type_of($name)"
    );
}

for my $name (qw( Maybe ArrayRef Object )) {
    ok(
        !t('Str')->is_a_type_of( t($name) ),
        "Str ! is_a_type_of($name)"
    );

    ok(
        !$str_clone->is_a_type_of( t($name) ),
        "Str clone ! is_a_type_of($name)"
    );
}

for my $type ( t('Str'), $str_clone ) {
    ok(
        $type->is_same_type_as( t('Str') ),
        $type->name . ' is_same_type_as Str'
    );
}

{
    my $child = anon( parent => t('Str') );
    ok(
        $child->can_be_inlined,
        'child of builtin with no additional constraint can be inlined'
    );
}

done_testing();
