#!/usr/bin/env perl
# Coverage for the col() filter DSL -- the pure-Perl operator overloading that
# builds predicate trees consumed by filter(). The coverage report shows the
# string operators lt / le / ge were never exercised; this drives all of them,
# in both operand orders (which flips the operator), and the &/|/! combinators.
use strict;
use warnings;
use Test::More;
use Stats::LikeR 'col';

# A col('x') OP value builds a Stats::LikeR::Pred leaf: { col, op, val }.
sub leaf_ok {
 my ($pred, $col, $op, $val, $name) = @_;
 isa_ok $pred, 'Stats::LikeR::Pred', "$name is a Pred";
 is $pred->{col}, $col, "$name: column";
 is $pred->{op},  $op,  "$name: operator";
 is $pred->{val}, $val, "$name: value";
}

# --- numeric comparisons (sanity; some already covered) -------------------
leaf_ok( col('age') >  18, 'age', '>',  18, 'age > 18'  );
leaf_ok( col('age') <= 65, 'age', '<=', 65, 'age <= 65' );
leaf_ok( col('n')   == 0,  'n',   '==', 0,  'n == 0'    );
leaf_ok( col('n')   != 0,  'n',   '!=', 0,  'n != 0'    );

# operand order flips the operator: 18 <= col('age')  ==  col('age') >= 18
leaf_ok( 18 <= col('age'), 'age', '>=', 18, '18 <= col(age) flips to >=' );
leaf_ok( 100 > col('x'),   'x',   '<',  100,'100 > col(x) flips to <'    );

# --- string comparisons: lt / le / ge / gt / eq / ne ----------------------
leaf_ok( col('s') lt 'm', 's', 'lt', 'm', 'col(s) lt m' );
leaf_ok( col('s') le 'm', 's', 'le', 'm', 'col(s) le m' );
leaf_ok( col('s') ge 'm', 's', 'ge', 'm', 'col(s) ge m' );
leaf_ok( col('s') gt 'm', 's', 'gt', 'm', 'col(s) gt m' );
leaf_ok( col('s') eq 'm', 's', 'eq', 'm', 'col(s) eq m' );
leaf_ok( col('s') ne 'm', 's', 'ne', 'm', 'col(s) ne m' );

# flipped string operators: 'm' lt col('s')  ==  col('s') gt 'm', etc.
leaf_ok( 'm' lt col('s'), 's', 'gt', 'm', "'m' lt col(s) flips to gt" );
leaf_ok( 'm' le col('s'), 's', 'ge', 'm', "'m' le col(s) flips to ge" );
leaf_ok( 'm' ge col('s'), 's', 'le', 'm', "'m' ge col(s) flips to le" );

# --- combinators: & (and), | (or), ! (not) --------------------------------
{
 my $and = (col('a') > 1) & (col('b') < 2);
 isa_ok $and, 'Stats::LikeR::Pred', 'and node';
 is $and->{op}, 'and', '& builds an "and" node';
 is $and->{l}{col}, 'a', 'and: left operand kept';
 is $and->{r}{col}, 'b', 'and: right operand kept';

 my $or = (col('a') > 1) | (col('b') < 2);
 is $or->{op}, 'or', '| builds an "or" node';

 my $not = !(col('a') > 1);
 is $not->{op},  'not', '! builds a "not" node';
 is $not->{l}{col}, 'a', 'not: operand kept';
 ok !defined $not->{r}, 'not: right operand is undef';
}

# --- end-to-end through filter(), when the compiled module is present ------
# (filter is an XSUB; skipped under the pure-Perl validation harness.)
SKIP: {
 skip 'filter() not available (pure-Perl harness)', 3
     unless Stats::LikeR->can('filter');
 my $df = [ { age => 10 }, { age => 20 }, { age => 30 } ];

 my $adults = Stats::LikeR::filter($df, col('age') >= 20);
 is scalar(@$adults), 2, 'filter keeps age >= 20';

 my $young = Stats::LikeR::filter($df, col('age') < 20);
 is scalar(@$young), 1, 'filter keeps age < 20';

 my $both = Stats::LikeR::filter($df, (col('age') > 5) & (col('age') < 25));
 is scalar(@$both), 2, 'filter honours an & predicate';
}

done_testing;
