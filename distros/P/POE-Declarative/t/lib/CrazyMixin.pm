use strict;
use warnings;

package CrazyMixin;
use base qw/ POE::Declarative::Mixin /;

use POE;
use POE::Declarative;
use Test::More;

require Exporter;
push our @ISA, 'Exporter';
our @EXPORT = qw( count );

sub import {
    my $class = shift;

    $class->export_to_level(1, undef);
    $class->export_poe_declarative_to_level;
}

on _start => run {
    on count_1 => run {
        is(get OBJECT, 'main');
        pass("count 1");
    };

    yield 'count';
};

on count_0 => run {
    is(get OBJECT, 'main');
    pass("count 0");
};

on count => run {
    declare_a_mixin(2);
    tell_someone_to_declare_a_mixin(3);
    tell_someone_else_to_declare_a_mixin(4);

    yield 'count_0';
    yield 'count_1';
    yield 'count_2';
    yield 'count_3';
    yield 'count_4';
};

on _default => run {
    return 0 unless get(ARG0) =~ /^count_\d+$/;
    fail('_default instead of '.get ARG0);
};

sub count($) {
    my $count = shift;
    on count => run { yield "count_$count" };
    return "count_$count";
}

sub declare_a_mixin {
    my $count = shift;

    on "count_$count" => run { 
        is(get OBJECT, 'main');
        pass("count $count") 
    };

    return;
}

sub tell_someone_to_declare_a_mixin {
    declare_a_mixin(shift);
}

sub tell_someone_else_to_declare_a_mixin {
    tell_someone_to_declare_a_mixin(shift);
}

1;
