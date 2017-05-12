
use strict;
use warnings;

use Data::Dumper;
use Test::Deep;

{
my ($tree, $node, @pnodes, @linear);
my %callback;
$callback{'open_paren'} = sub {
    push @pnodes, $node;
    push @{ $pnodes[-1] }, $node = [];
    push @linear, '(';
};
$callback{'close_paren'} = sub { $node = pop @pnodes; push @linear, ')' };
$callback{'operator'} = sub { push @$node, $_[0]; push @linear, '<operator, '. $_[0] .'>'; };
$callback{'operand'} = sub { push @$node, { operand => $_[0] }; push @linear, '<operand, "'. $_[0] .'">' };
$callback{'error'} = sub { die "$_[0]\n\nAt this point we have: ". Dumper \@linear; };
    
sub parse_cmp($$$) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($parser, $string, $expected) = @_;

    $node = $tree = [];
    @pnodes = @linear = ();

    $parser->parse( string => $string, callback => \%callback );
    cmp_deeply $tree, $expected, $string or diag Dumper $tree;
} }

1;
