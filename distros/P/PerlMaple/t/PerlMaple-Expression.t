#: PerlMaple-Expression.t
#: 2005-12-19 2006-02-06

use strict;
use warnings;

use Test::More tests => 125;
use Test::Deep;

my $pack;
BEGIN {
    $pack = 'PerlMaple::Expression';
    use_ok($pack);
}

my $ast = $pack->new;
ok !defined $ast, 'empty expr results in undef obj';

$ast = $pack->new('3');
my $ast2 = $pack->new('4');
ok $ast, 'obj ok';
isa_ok $ast, $pack;
is $ast->expr, '3', 'method expr';
ok $ast == 3, 'overloaded == operator';
ok $ast != 5, 'overloaded != operator';

# check the ast internals
is $ast->expr, 3;
is $ast->type, 'integer';
is $ast->nops, 1;
is join(' ', $ast->ops), '3';

is $ast->type, 'integer', 'method type';
ok $ast->type('integer'), 'method type';
ok $ast->type('type'), 'method type';
ok $ast->type('nonnegative'), 'method type';
ok not $ast->type('float');
ok not $ast->type('list');

$ast = $ast->new('3.5');
ok $ast, 'obj ok';
isa_ok $ast, $pack;
is $ast->expr, '3.5';

my $maple = $PerlMaple::Expression::maple;
is $maple->floor($ast), '3';
is $maple->ceil($ast), '4';
is int($ast)+3, 6;
ok $ast == 3.5;
ok $ast != 3.6;
ok $ast < 3.6;
ok not $ast > 3.6;
ok $ast <= 3.6;
ok $ast > 2;
ok 2 < $ast;

# level 1 test:
is $ast->nops, 2;
is $ast->type, 'float';
is $ast->expr, '3.5';
my @ops = $ast->ops;

# level 2 test:
is join(' ', @ops), '35 -1';

# level 3 test:
is $ops[0]->nops, 1;
is $ops[0]->type, 'integer';
is $ops[0]->expr, '35';
is join(' ', $ops[0]->ops), 35;
##
is $ops[1]->nops, 1;
is $ops[1]->type, 'integer';
is $ops[1]->expr, '-1';
is join(' ', $ops[1]->ops), -1;

is $ast->type, 'float';
ok $ast->type('float');
ok $ast->type('type');
ok $ast->type('numeric');
ok not $ast->type('integer');
ok not $ast->type('list');

cmp_deeply([$ast->ops], \@ops);

$ast = $ast->new("[3,42,'a']");
ok $ast, 'obj ok';
isa_ok $ast, $pack;
is $ast->expr, "[3, 42, a]", 'method expr';

# level 1 test:
is $ast->nops, 3;
is $ast->type, 'list';
is $ast->expr, '[3, 42, a]';
@ops = $ast->ops;
is join(' ', @ops), '3 42 a';

# level 2 test:
my $op = $ops[0];
is $op->nops, 1;
is $op->type, 'integer';
is $op->expr, '3';
is join(' ', $op->ops), '3';

$op = $ops[1];
is $op->nops, 1;
is $op->type, 'integer';
is $op->expr, '42';
is join(' ', $op->ops), '42';

$op = $ops[2];
is $op->nops, 1;
is $op->type, 'symbol';
is $op->expr, 'a';
is join(' ', $op->ops), 'a';

# other stuff:
is $ast->type, 'list';
ok not $ast->type('float');
ok not $ast->type('numeric');
ok not $ast->type('integer');
ok $ast->type('list');
ok not $ast->type('type');

cmp_deeply [$ast->ops], \@ops;

my @elems;
foreach my $elem ($ast->ops) {
    push @elems, $elem->expr;
}
cmp_deeply \@elems, [qw(3 42 a)];

$ast = $pack->new('2,      3');
ok $ast;
isa_ok $ast, $pack;

# level 1:
is $ast->nops, 2;
is $ast->type, 'exprseq';
is $ast->expr, '2, 3';
@ops = $ast->ops;
is join(' ', @ops), '2 3';

# level 2:
$op = $ops[0];
isa_ok $op, $pack;
is $op->nops, 1;
is $op->type, 'integer';
is $op->expr, '2';
is join(' ', $op->ops), '2';
  ##
$op = $ops[1];
isa_ok $op, $pack;
is $op->nops, 1;
is $op->type, 'integer';
is $op->expr, '3';
is join(' ', $op->ops), '3';

# other stuff:
is $ast->type, 'exprseq';
ok $ast->type('exprseq');
ok not $ast->type('type');
ok not $ast->type('list');

$ast = PerlMaple::Expression->new('2,        3,4');
is $ast->expr, '2, 3, 4';

$ast = PerlMaple::Expression->new('2,        3,4', 1);
is $ast->expr, '2,        3,4';

$ast = PerlMaple::Expression->new('[7,8,9]');
@ops = $ast->ops;
is $ops[0]->expr, 7;
is $ops[0], 7;
is $ops[1]->expr, 8;
is $ops[1], 8;
is $ops[2]->expr, 9;
is $ops[2], 9;

my $expr = PerlMaple::Expression->new('x^3+2*x-1');
is $expr->expr, 'x^3+2*x-1';

is "$expr", 'x^3+2*x-1', 'overloaded stringify ("") operator';
ok $expr eq 'x^3+2*x-1', 'overloaded eq operator';
ok $expr ne 'x^3 + 2*x - 1', 'overloaded eq operator';

is $expr->type, '`+`';
my @a = $expr->ops;
ok @a;
my @b = map { $_->expr } @a;
cmp_deeply \@b, ['x^3', '2*x', '-1'];

is $a[0]->type, '`^`';
@b = map { $_->expr } $a[0]->ops;
cmp_deeply \@b, ['x', '3'];

is $a[1]->type, '`*`';
@b = map { $_->expr } $a[1]->ops;
cmp_deeply \@b, ['2', 'x'];

use List::Util 'first';
$maple = PerlMaple->new(ReturnAST => 1);
ok $maple;
ok $maple->eval_cmd('s:={a(n) = 9*a(n-1)+b(n-1), b(n) = a(n-1)+9*b(n-1), a(1) = 8, b(1) = 1};');
my $res = $maple->rsolve("s", "{a(n),b(n)}");
like $res, qr/a\(n\)/;
my $a_n;
if ($res->type('set')) {
    $a_n = first { $_->lhs eq 'a(n)' } $res->ops;
    $a_n = $a_n->rhs;
}
@a = map { $a_n->eval("n=$_") } 1..4;
is join(',', @a), '8,73,674,6292';

$expr = PerlMaple::Expression->new( '(3+n)*(n^2+1)' );
ok $expr;
is $expr->expand->testeq('3*n^2+3+n^3+n'), 'true';
is $expr->eval('n=1'), 8;

$expr = PerlMaple::Expression->new( '[]' );
ok $expr;
@a = $expr->ops;
is_deeply \@a, [];

$maple->ReturnAST(1);
$expr = PerlMaple::Expression->new('ssss');
ok $expr;
