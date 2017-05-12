# -*- mode: cperl; -*-
use Test::Base;
use String::IRC;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $x = String::IRC->new( $block->input );

    my ($fg, $bg) = split /\s+/, $block->name;
    $x->$fg($bg);

    is "$x", $block->expect, $block->name;
};

__END__
=== yellow red
--- input:  hello
--- expect: 08,04hello
=== red yellow
--- input:  hello
--- expect: 04,08hello
=== red cyan
--- input:  hello
--- expect: 04,11hello
