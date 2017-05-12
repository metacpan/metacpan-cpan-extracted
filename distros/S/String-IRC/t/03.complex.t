# -*- mode: cperl; -*-
use Test::Base;
use String::IRC;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $x = String::IRC->new( $block->input );

    my @methods = split /\s+/, $block->name;
    $x->$_() for @methods;

    is "$x", $block->expect, $block->name;
};

__END__
=== bold yellow
--- input:  hello
--- expect: 08hello
=== bold yellow underline
--- input:  hello
--- expect: 08hello
=== bold yellow underline inverse
--- input:  hello
--- expect: 08hello
