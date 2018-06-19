use strict;
use warnings;
use Test::More;
use Encode;
use Sort::Naturally::XS;

my $ar_wo_digit = [reverse(map {$_ x 2} ('a'..'z'))];
my $ar_wo_digit__expected = [reverse(@{$ar_wo_digit})];
ok(eq_array($ar_wo_digit__expected, [nsort(@{$ar_wo_digit})]), 'Char only sort');

my $ar_digit = [reverse(map {$_ x 2} (1..10))];
my $ar_digit__expected = [reverse(@{$ar_digit})];
ok(eq_array($ar_digit__expected, [nsort(@{$ar_digit})]), 'Digit only sort');

# CCXX-1 test
my $ar_mostly_digit = [qw/1100x1400 2000x2200 1400x2050 2200x2400 1500x2000 2200x2600 1720x2050 2400x2400 1800x2200
    2400x2600/];
my $ar_mostly_digit__expected = [qw/1100x1400 1400x2050 1500x2000 1720x2050 1800x2200 2000x2200 2200x2400 2200x2600
    2400x2400 2400x2600/];
ok(eq_array($ar_mostly_digit__expected, [nsort(@{$ar_mostly_digit})]), 'Dimensions sort');

my $ar_mixed_simple = [qw/test21 test20 test10 test11 test2 test1/];
my $ar_mixed_simple__expected = [qw/test1 test2 test10 test11 test20 test21/];
ok(eq_array($ar_mixed_simple__expected, [nsort(@{$ar_mixed_simple})]), 'Mixed sort');

# Sort::Naturally example
my $ar_mixed_example = [qw/foo12a foo12z foo13a foo 14 9x foo12 fooa foolio Foolio Foo12a/];
my $ar_mixed_example__expected = [qw/9x 14 Foo12a Foolio foo foo12 foo12a foo12z foo13a fooa foolio/];
ok(eq_array($ar_mixed_example__expected, [nsort(@{$ar_mixed_example})]), 'Sort::Naturally example');

# compatibility with Sort::Naturally test
my @mixed_list = (qw/foo12a foo12z foo13a foo 14 9x foo12 fooa foolio Foolio Foo12a/);
my @mixed_list__original = @mixed_list;
my @mixed_list__expected = (qw/9x 14 Foo12a Foolio foo foo12 foo12a foo12z foo13a fooa foolio/);
my @mixed_list__actual = nsort(@mixed_list);
ok(eq_array(\@mixed_list__expected, \@mixed_list__actual), 'Sort::Naturally sorting OK');
ok(eq_array(\@mixed_list__original, \@mixed_list), 'Sort::Naturally original list is not changed');

# CCXX-2 test
my $ar_mixed_strong = [qw/H4 T25 H5 T27 H8 T30 HEX T35 M10 T4 M12 T40 M13 T45 M14 T47 M16 T5 M4 T50 M5 T55 M6 T6 M7 T60
    M8 T7 M9 T70 Ph0 T8 Ph1 T9 Ph2 TT10 Ph3 TT15 Ph4 TT20 Pz0 TT25 Pz1 TT27 Pz2 TT30 Pz3 TT40 Pz4 TT45 R10 TT50 R12 TT55
    R13 TT6 R14 TT60 R5 TT7 R6 TT70 R7 TT8 R8 TT9 S TX Sl XZN T10 держатель T15 набор T20/];
my $ar_mixed_strong__expected = [qw/H4 H5 H8 HEX M4 M5 M6 M7 M8 M9 M10 M12 M13 M14 M16 Ph0 Ph1 Ph2 Ph3 Ph4 Pz0 Pz1 Pz2
    Pz3 Pz4 R5 R6 R7 R8 R10 R12 R13 R14 S Sl T4 T5 T6 T7 T8 T9 T10 T15 T20 T25 T27 T30 T35 T40 T45 T47 T50 T55 T60 T70
    TT6 TT7 TT8 TT9 TT10 TT15 TT20 TT25 TT27 TT30 TT40 TT45 TT50 TT55 TT60 TT70 TX XZN держатель набор/];
ok(eq_array($ar_mixed_strong__expected, [nsort(@{$ar_mixed_strong})]), 'CCXX test');

# unicode test
my $ar_mixed_utf8 = [qw/Як-100 Ка-8 Ми-20 Ка-10 Ка-26 Ка-15 Ка-25 Ми-4 Ми-6 Ми-8 Ка-31 Ми-14 Ми-24 Ка-18 Ка-22 Ми-26
    Ми-30 Ми-171 Як-24 Як-60 Ка-27 Ка-29 Ка-32 Ка-126 Ми-10 Ми-1/];
my $ar_mixed_utf8__expected = [qw/Ка-8 Ка-10 Ка-15 Ка-18 Ка-22 Ка-25 Ка-26 Ка-27 Ка-29 Ка-31 Ка-32 Ка-126 Ми-1 Ми-4 Ми-6
    Ми-8 Ми-10 Ми-14 Ми-20 Ми-24 Ми-26 Ми-30 Ми-171 Як-24 Як-60 Як-100/];
ok(eq_array($ar_mixed_utf8__expected, [nsort(@{$ar_mixed_utf8})]), 'UTF-8 test');

my $ar_mixed_cp1251 = [map {Encode::encode('cp1251', Encode::decode('utf8', $_))} @{$ar_mixed_utf8}];
my $ar_mixed_cp1251__expected =
    [map {Encode::encode('cp1251', Encode::decode('utf8', $_))} @{$ar_mixed_utf8__expected}];
ok(eq_array($ar_mixed_cp1251__expected, [nsort(@{$ar_mixed_cp1251})]), 'WINDOWS-1251 test');

my @empty_list;
ok(eq_array([], [nsort(@empty_list)]), 'Returns empty list in list context if argument is empty list');

my $scalar_undef = nsort(@empty_list);
is($scalar_undef, undef, 'Returns undef in scalar context if argument is empty list');

done_testing();
