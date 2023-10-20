# -*- mode: cperl; -*-
use Test::Base;
use String::IRC;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $x = String::IRC->new( $block->input );

    my $method = $block->name;
    $x->$method();

    is "$x", $block->expect, $block->name;
};

__END__
=== bold
--- input:  hello
--- expect: hello
=== underline
--- input:  hello
--- expect: hello
=== inverse
--- input:  hello
--- expect: hello
