#!perl -T

use strict;
use warnings;
use Test::Base;
use Tie::IxHash;

use PHP::Var;

plan tests => 1*blocks;

filters {
    hash     => [qw/chomp/],
    array    => [qw/chomp/],
    scalar   => [qw/chomp/],
    expected => [qw/chomp/],
    enclose  => [qw/chomp/],
    purity   => [qw/chomp/],
    var      => [qw/chomp/],
};

run {
    my $block = shift;
    my ($expected, $data);

    if ($block->hash) {
        my %hash;
        tie(%hash, 'Tie::IxHash');
        %hash = eval($block->hash);
        $data = \%hash;
    }
	elsif ($block->scalar) {
		my $scalar = eval($block->scalar);
		$data = \$scalar;
	}
    else {
        my @array = eval($block->array);
        $data = \@array;
    }

    if ($expected = $block->expected) {
        is(PHP::Var::export($data), $expected);
    }
    elsif ($expected = $block->var) {
        is(PHP::Var::export('var' => $data), $expected);
    }
    elsif ($expected = $block->enclose) {
        is(PHP::Var::export($data, enclose => 1), $expected);
    }
    elsif ($expected = $block->purity) {
        is(PHP::Var::export($data, purity => 1), $expected);
    }
};

sub eval_string {
    eval('"' . $_[0] . '"');
}

__END__

=== Simple Scalar
--- scalar
'a'
--- expected
'a';

=== Simple Hash
--- hash
(a => 'b', c => 'd')
--- expected
array('a'=>'b','c'=>'d',);

=== Simple Array
--- array
([1, 2], 3)
--- expected
array(array('1','2',),'3',);

=== Named
--- hash
(a => 'b', c => 'd')
--- var
$var=array('a'=>'b','c'=>'d',);

=== Deep
--- hash
(a => {'b' => {'c' => 'd'}})
--- var
$var=array('a'=>array('b'=>array('c'=>'d',),),);

=== Escape
--- hash
(a => "b'abb", b => "a\tb\rc\n")
--- var eval_string
\$var=array('a'=>'b\\'abb','b'=>'a\tb\rc\n',);

=== Zero
--- hash
(a => 0)
--- var
$var=array('a'=>'0',);

=== Undef
--- hash
(a => undef)
--- var
$var=array('a'=>false,);

=== Empty
--- hash
(a => '')
--- var
$var=array('a'=>'',);

=== Enclose
--- hash
(a => 'b', c => 'd')
--- enclose
<?php
array('a'=>'b','c'=>'d',);
?>

=== Purity Hash
--- hash
(a => {b => {c => 'd'}})
--- purity
array(
	'a' => array(
		'b' => array(
			'c' => 'd',
		),
	),
);

=== Purity Array
--- array
([[1, 2], 3], 4)
--- purity
array(
	array(
		array(
			'1',
			'2',
		),
		'3',
	),
	'4',
);
