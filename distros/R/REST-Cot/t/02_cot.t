use strict;
use warnings;
use Test::More;

use_ok 'REST::Cot';
my $cot = REST::Cot->new('http://localhost');

isa_ok $cot, 'REST::Cot::Fragment'
    or diag ref($cot);
can_ok $cot, qw[GET POST PUT PATCH DELETE OPTIONS HEAD];
isa_ok $cot->{client}, 'REST::Client';

ok my $a = $cot->a->b->c->d;
is "$a", '/a/b/c/d';
is ~$a, '/a';

ok my $b = $cot->a('foo');
is "$b", '/a/foo';

ok my $c = $cot->a->b('foo');
is "$c", '/a/b/foo';

ok my $d = $cot->a->b('buzz');
is "$d", '/a/b/buzz';

ok my $e = $cot->a->b('fizz')->dang;
is "$e", '/a/b/fizz/dang';


done_testing;
