use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Data::SExpression::Lite;
use Data::Dumper;

my $sexp = Data::SExpression::Lite->new();
is_deeply($sexp->parse('()'), []);
is_deeply($sexp->parse('(a b c)'), [qw(a b c)]);
is_deeply($sexp->parse('(a (b c))'), ['a', ['b', 'c']]) or diag Dumper($sexp->parse('(a (b c))'));

done_testing;

