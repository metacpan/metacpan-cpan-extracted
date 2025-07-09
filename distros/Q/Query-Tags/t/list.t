use v5.16;
use Test::More;
use Scalar::Util qw(blessed);
use Pegex;
use Query::Tags::Grammar;
use Query::Tags::To::AST;

my $s = q[</a b [c]+/ def_ghi 'jkl  mn0'   123.456>];
my @vals = (
    Query::Tags::To::AST::Regex->new(qr/a b [c]+/),
    Query::Tags::To::AST::String->new("def_ghi"),
    Query::Tags::To::AST::String->new("jkl  mn0"),
    Query::Tags::To::AST::String->new("123.456"),
);

my $r = Pegex::Parser->new(
    grammar  => Query::Tags::Grammar->new,
    receiver => Query::Tags::To::AST->new,
)->parse($s, 'list');

for my $v (@$r) {
    state $i;
    my $w = $vals[$i++];
    isa_ok $v, blessed $w;
    #is "". $p->value, $vals[$i++], 'correct value';
}

done_testing;
