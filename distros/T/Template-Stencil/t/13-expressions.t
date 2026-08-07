#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub inspect { Template::Stencil::_inspect($_[0]) }
sub opnames { [ map $_->{op}, @{ inspect($_[0])->{ops} } ] }

# Plain if: TEST_JF jumps to the end of the block.
{
    my $ops = inspect('{% if a %}x{% end %}')->{ops};
    is_deeply([ map $_->{op}, @$ops ],
              [qw(SOP_PUSH_PATH SOP_TEST_JF SOP_LITERAL_SHORT SOP_END)],
              'if shape');
    is($ops->[1]{target}, $ops->[3]{at}, 'TEST_JF targets block end');
}

# if/else: TEST_JF to the else body, JUMP over it.
{
    my $ops = inspect('{% if a %}x{% else %}y{% end %}')->{ops};
    is_deeply([ map $_->{op}, @$ops ],
              [qw(SOP_PUSH_PATH SOP_TEST_JF SOP_LITERAL_SHORT SOP_JUMP
                  SOP_LITERAL_SHORT SOP_END)],
              'if/else shape');
    is($ops->[1]{target}, $ops->[4]{at}, 'TEST_JF targets else body');
    is($ops->[3]{target}, $ops->[5]{at}, 'JUMP targets block end');
}

# elsif chain.
{
    my $ops = inspect('{% if a %}1{% elsif b %}2{% else %}3{% end %}')->{ops};
    is_deeply([ map $_->{op}, @$ops ],
              [qw(SOP_PUSH_PATH SOP_TEST_JF SOP_LITERAL_SHORT SOP_JUMP
                  SOP_PUSH_PATH SOP_TEST_JF SOP_LITERAL_SHORT SOP_JUMP
                  SOP_LITERAL_SHORT SOP_END)],
              'if/elsif/else shape');
    is($ops->[1]{target}, $ops->[4]{at}, 'first test falls to elsif');
    is($ops->[5]{target}, $ops->[8]{at}, 'second test falls to else');
    is($ops->[3]{target}, $ops->[9]{at}, 'both jumps target end');
    is($ops->[7]{target}, $ops->[9]{at}, 'both jumps target end');
}

# unless swaps the test.
is(inspect('{% unless a %}x{% end %}')->{ops}[1]{op}, 'SOP_TEST_JT',
   'unless uses TEST_JT');

# Precedence: && binds tighter than ||.
{
    my $ops = inspect('{% if a || b && c %}x{% end %}')->{ops};
    is_deeply([ map $_->{op}, @$ops[0 .. 6] ],
              [qw(SOP_PUSH_PATH SOP_JT_KEEP SOP_POP SOP_PUSH_PATH
                  SOP_JF_KEEP SOP_POP SOP_PUSH_PATH)],
              'a || (b && c) shape');
}

# Parentheses override.
{
    my $ops = inspect('{% if (a || b) && c %}x{% end %}')->{ops};
    is_deeply([ map $_->{op}, @$ops[0 .. 6] ],
              [qw(SOP_PUSH_PATH SOP_JT_KEEP SOP_POP SOP_PUSH_PATH
                  SOP_JF_KEEP SOP_POP SOP_PUSH_PATH)],
              '(a || b) && c shape');
    # the JT_KEEP inside the parens must target the JF_KEEP site, not
    # the end of the whole expression
    my ($jt) = grep { $_->{op} eq 'SOP_JT_KEEP' } @$ops;
    my ($jf) = grep { $_->{op} eq 'SOP_JF_KEEP' } @$ops;
    is($jt->{target}, $jf->{at}, 'paren group closes before &&');
}

# Typed comparison selection from the operator spelling.
my %cmp = (
    '=='  => 'SOP_EQ_NUM', '!=' => 'SOP_NE_NUM',
    '<'   => 'SOP_LT_NUM', '>'  => 'SOP_GT_NUM',
    '<='  => 'SOP_LE_NUM', '>=' => 'SOP_GE_NUM',
    'eq'  => 'SOP_EQ_STR', 'ne' => 'SOP_NE_STR',
    'lt'  => 'SOP_LT_STR', 'gt' => 'SOP_GT_STR',
    'le'  => 'SOP_LE_STR', 'ge' => 'SOP_GE_STR',
);
for my $op (sort keys %cmp) {
    my $ops = opnames("{% if a $op b %}x{% end %}");
    is($ops->[2], $cmp{$op}, "'$op' compiles to $cmp{$op}");
}

# not / ! negation, including on comparisons.
{
    my $ops = opnames('{% if !a %}x{% end %}');
    is($ops->[1], 'SOP_NOT', 'bang negation');
    $ops = opnames('{% if not a == b %}x{% end %}');
    is_deeply([ @$ops[0 .. 3] ],
              [qw(SOP_PUSH_PATH SOP_PUSH_PATH SOP_EQ_NUM SOP_NOT)],
              'not binds looser than comparison');
}

# Literals.
{
    my $ops = inspect(q[{% if a eq 'x\'y' %}v{% end %}])->{ops};
    is($ops->[1]{op}, 'SOP_PUSH_LIT_STR', 'string literal pushed');
    is($ops->[1]{bytes}, "x'y", 'escaped quote unescaped');
    $ops = inspect('{% if a == 3.5 %}v{% end %}')->{ops};
    is($ops->[1]{op}, 'SOP_PUSH_LIT_NUM', 'number literal pushed');
    cmp_ok(abs($ops->[1]{num} - 3.5), '<', 1e-12, 'number value');
    $ops = inspect('{% if a == -2 %}v{% end %}')->{ops};
    cmp_ok($ops->[1]{num}, '==', -2, 'negative number');
}

# undef and defined().
{
    my $ops = opnames('{% if a eq undef %}v{% end %}');
    is($ops->[1], 'SOP_PUSH_UNDEF', 'undef literal');
    $ops = opnames('{% if defined(a.b) %}v{% end %}');
    is_deeply([ @$ops[0, 1] ], [qw(SOP_PUSH_PATH SOP_DEFINED)],
              'defined(path)');
}

# set takes a full expression and keeps Perl value semantics via the
# KEEP jumps.
{
    my $ops = inspect('{% set x = a || b %}')->{ops};
    is_deeply([ map $_->{op}, @$ops ],
              [qw(SOP_PUSH_PATH SOP_JT_KEEP SOP_POP SOP_PUSH_PATH
                  SOP_SET SOP_END)],
              'set with || keeps deciding operand');
    is($ops->[4]{name}, 'x', 'set binds the name');
    is($ops->[1]{target}, $ops->[4]{at}, 'JT_KEEP lands on the SET');
}

# Filters compile to table entries with compile-time builtin ids.
{
    my $ops = inspect(q[{% price | trim | default('0.00') %}])->{ops};
    my @f = grep { $_->{op} eq 'SOP_FILTER' } @$ops;
    is(scalar @f, 2, 'two filters chained');
    is($f[0]{filter}, 'trim', 'first filter name');
    cmp_ok($f[0]{builtin_id}, '>=', 0, 'trim resolved builtin');
    is($f[1]{filter}, 'default', 'second filter name');
    is($f[1]{arg}, '0.00', 'default argument');
    is($ops->[-2]{op}, 'SOP_PRINT_ESC', 'escape after filters');
}
{
    my $ops = inspect('{% raw body | custom_thing(3) %}')->{ops};
    my ($f) = grep { $_->{op} eq 'SOP_FILTER' } @$ops;
    is($f->{builtin_id}, -1, 'unknown filter marked user');
    cmp_ok($f->{arg}, '==', 3, 'numeric filter arg');
    is($ops->[-2]{op}, 'SOP_PRINT_RAW', 'raw print after filters');
}

done_testing;
