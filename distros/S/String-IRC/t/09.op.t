# -*- mode: cperl; -*-
use Test::Base;
use String::IRC;

plan tests => 4 * blocks;

run {
    my $block = shift;
    my $x = String::IRC->new( $block->input );

    my @methods = split /\s+/, $block->name;
    $x->$_() for @methods;

    is "$x",             $block->expect, $block->name.q{: double quote};
    is $x->stringify,    $block->expect, $block->name.q{: stringify};
    is "".$x,            $block->expect, $block->name.q{: concat};
    is sprintf("%s",$x), $block->expect, $block->name.q{: sprintf};
};

__END__
=== bold yellow
--- input:  hello
--- expect: 08hello
