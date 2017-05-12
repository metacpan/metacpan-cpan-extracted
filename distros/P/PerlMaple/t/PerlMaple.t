#: PerlMaple.t
#: 2005-11-14 2006-02-06

use strict;
use warnings;

use Test::More tests => 48;
use Test::Deep;
BEGIN { use_ok('PerlMaple') }

my $maple = PerlMaple->new;
ok $maple;
ok !defined $maple->error;
isa_ok($maple, 'PerlMaple');

ok $maple->PrintError;
ok not $maple->RaiseError;

my $ans = $maple->eval_cmd('eval(int(2*x^3,x), x=2);');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval('eval(int(2*x^3,x), x=2)');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd("eval(int(2*x^3,x), x=2);  \n \n\r");
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd("eval(int(2*x^3,x), x=2");
ok !defined $ans;
ok $maple->error;
like $maple->error, qr/unexpected end of/i;

$maple = PerlMaple->new(
  PrintError => 0,
  RaiseError => 1,
);
ok $maple;
isa_ok $maple, 'PerlMaple';

ok not $maple->PrintError;
ok $maple->RaiseError;

$maple->RaiseError(undef);
ok not $maple->PrintError;
ok not $maple->RaiseError;

$ans = $maple->eval_cmd("3+1");
ok !defined $ans;
ok $maple->error;
like $maple->error, qr/unexpected end of/i;

$ans = $maple->eval('int(2*x^3,x)', 'x=2');
is $ans, 8;
ok !defined $maple->error;

my $exp = $maple->int('2*x^3', 'x');
$ans = $maple->eval($exp, 'x=2');
is $ans, 8;
ok !defined $maple->error;

$ans = $maple->eval_cmd(<<'.');
lc := proc( s, u, t, v )
         description "form a linear combination of the arguments";
         s * u + t * v
end proc;
.

like $ans, qr/proc.*description/;
ok !defined $maple->error;

$maple->eval('3+2');
is $maple->eval_cmd('3+1:'), '';

##########################
# Test AST related stuff:
##########################

{ # Test ->to_ast

    my $pack = 'PerlMaple::Expression';

    my $ast = $maple->to_ast;
    ok !defined $ast, 'empty expr results in undef obj';

    $ast = $maple->to_ast('3');
    ok $ast, 'obj ok';
    isa_ok $ast, $pack;
    is $ast->expr, '3', 'method expr';

    # check the ast internals
    is $ast->type, 'integer';
    is $ast->nops, 1;
    is join(' ', $ast->ops), '3';

    $ast = $maple->to_ast('2,        3,4', 1);
    is $ast->expr, '2,        3,4';

    $ast = $maple->to_ast('2,        3,4');
    is $ast->expr, '2, 3, 4';

}

# Test the ReturnAST attribute:
ok not $maple->ReturnAST;
my $res = $maple->solve('x^2+1/2*x=0', 'x');
ok not ref($res);
like $res, qr[-1/2];

$maple->ReturnAST(1);
ok $maple->ReturnAST;

my $ast = $maple->solve('x^2+1/2*x=0', 'x');
my @roots;
if ($ast->type('exprseq')) {
  foreach ($ast->ops) {
      push @roots, $_->expr;
  }
}
cmp_deeply \@roots, bag(0, '-1/2');

$maple->ReturnAST(0);
ok not $maple->ReturnAST;

$maple->ReturnAST(1);
$maple->ReturnAST(undef);
ok not $maple->ReturnAST;

$maple->ReturnAST(0);
my $output = $maple->eval_cmd('with(plots):');
unlike $output, qr/Warning/i, 'no warning message returned';
