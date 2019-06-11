#!/usr/bin/perl
use warnings;
use strict;

use constant MAY_WORK_IN_OLDER => 'may work in older';

my $can_have_plan;

BEGIN {
    require Test::More;

    # Implements "done_testing".
    if ($can_have_plan = eval { Test::More->VERSION('0.88') }) {
        'Test::More'->import;
    } else {
        'Test::More'->import('no_plan');
    }
}

use Syntax::Construct ();


sub skippable {
    my ($test, $reason, $value) = @_;
    return "SKIP: { $test or skip $reason, 1; return $value } 'SKIPPED'"
}


my %tests = (
    '5.030' => [
        [ 'unicode12.1',
          '"\N{FREEZING FACE}\N{SLOTH}\N{SQUARE ERA NAME REIWA}"'
          . ' eq "\N{U+1F976}\N{U+1F9A5}\N{U+32FF}"',
          1 ],
        [ 'uniprop_wildcards',
          '"\N{ORIYA DIGIT FOUR}" =~ m{\p{nv=/\A[0-5]\z/}}', 1 ],
        [ "qr'N",
          q("\N{ORIYA DIGIT FOUR}" =~ m'\N{ORIYA DIGIT FOUR}'), 1 ],
        [ 'turkic-casing',
          'use locale; use POSIX "locale_h";'
          . skippable('setlocale(LC_ALL, "tr_TR.UTF-8")',
                      '": testing locale not available"',
                      'lc "I" eq "\N{LATIN SMALL LETTER DOTLESS I}"'),
          1 ],
    ],

    '5.028' => [
        [ 'delete%',
          'my %h = ( a => 12, b => 13, c => 14);'
              . ' join " ", sort delete %h{"a", "b"}',
          '12 13 a b' ],
        [ 'unicode10.0',
          '"\N{T-REX}" eq "\N{U+1F996}"', 1 ],
        [ 'state@=',
          'use feature "state"; sub { state @x = qw( a b ); "@x" }->()', 'a b'
        ],
    ],

    '5.026' => [
        [ '<<~',
          "<<~ 'EOF'\n a\n EOF", "a\n" ],
        [ '/xx',
          '" " !~ /[a b]/xx', 1 ],
        [ '^CAPTURE',
          '"ab" =~ /(.)(.)/; "@{^CAPTURE}"', "a b" ],
        [ 'unicode9.0',
          '"\N{BUTTERFLY}" eq "\N{U+1F98B}"', 1 ],
        [ 'unicode-scx',
          '"\N{KATAKANA-HIRAGANA DOUBLE HYPHEN}" !~ /\p{Common}/', 1],
    ],

    '5.024' => [
        [ 'unicode8.0',
          '"\N{OLD HUNGARIAN CAPITAL LETTER A}" eq "\N{U+10C80}"', 1 ],
        [ '\b{lb}',
          '"1\n2" =~ /\b{lb}/', '1' ],
        [ 'sprintf-reorder',
          'sprintf q(|%.*2$d|), 7, 3', '|007|' ],
    ],

    '5.022' => [
        [ '<<>>',
          'local @ARGV = $0; chomp(my $line = <<>>); $line',
          '#!/usr/bin/perl' ],
        [ '\b{}',
          q("O'Connor" =~ /O\B{wb}'/), 1 ],
        [ '/n',
          '"abc" =~ /(.)/n; !$1', 1 ],
        [ 'unicode7.0',
          '"\N{U+11600}" =~ /\p{Modi}/', 1],
        [ 'attr-const',
          'my $c = sub () :const { int rand 10 };'
              . 'join(",", map $c->(), 1 .. 10) =~ /^([0-9])(?:,\1){9}$/',
          1 ],
        [ 'fileno-dir', 'use File::Spec;'
              . skippable('opendir my $D, "File::Spec"->curdir',
                          '": $!"',
                          'defined fileno $D || !! $!'),
          1, MAY_WORK_IN_OLDER ],  # $! might be set.
        [ '()x=',
          '((undef) x 2, my $x) = qw(a b c); $x', 'c' ],
        [ 'hexfloat',
          '0xFFp-1', 127.5 ],
        [ 'chr-inf',
          'eval { chr "Inf" } or substr($@, 0, 14)', 'Cannot chr Inf' ],
        [ 'empty-slice',
          'scalar grep 1, (1)[1,2,3]', 3,
          MAY_WORK_IN_OLDER ],  # Worked in 5.8.
        [ '/x-unicode',
          'my $s = " \N{U+0085}\N{U+200E}\N{U+200F}\N{U+2028}\N{U+2029}";'
          . '"ab" =~ /a${s}b/x', 1 ]
    ],

    '5.020' => [
        [ 'attr-prototype',
          'sub func : prototype($$) {} prototype \&func', '$$' ],
        [ 'drand48',
          'srand 42; join " ", map int rand 1000, 1 .. 20',
          '744 342 111 422 81 856 498 478 690 834 462 577 533 25 769 601 908 489 535 496',
          MAY_WORK_IN_OLDER ],  # Platform dependant.
        [ '%slice',
          'my %h = my @l = qw(a A b B); join ":", %h{qw(a b)}, %l[0, 3]',
          'a:A:b:B:0:a:3:B' ],
        [ 'unicode6.3',
          'my $i; /\p{Age: 6.3}/ and $i++ for map chr, 0 .. 0xffff; $i', 5 ],
        [ '\p{Unicode}',
          'scalar grep $_ =~ /\p{Unicode}/, "a", "\N{U+0FFFFF}"', 2 ],
        [ 's-utf8-delimiters',
          eval q("'a' =~ s\N{U+2759}a\N{U+2759}b\N{U+2759}r"), 'b' ],
        # TODO: 'utf8-locale'.
    ],

    '5.018' => [
        [ 'computed-labels',
          'my $x = "A"; B:while (1) { A:while (1) { last $x++ }}; 1', 1],
        [ 'while-each',
          'my %h = qw( A a B b C c ); my ($k, $v);'
          . '$k .= $_, $v .= $h{$_} while each %h;'
          . '$k =~ /^[ABC]{3}$/ && $v =~ /^[abc]{3}$/ ',
          1 ],
    ],

    '5.014' => [
        [ '?^',
          '"Ab" =~ /(?i)a(?^)b/', 1],
        [ '/r',
          'my $x = "abc"; $x =~ s/c/d/r', 'abd'],
        [ '/a',
          '"\N{U+0e0b}" =~ /^\w$/a', q()],
        [ '/u',
          '"\xa0\xe0" =~ /\w/u', 1],
        [ 'auto-deref',
          'my ($x, $y, $z) = ([10, 20, 30], {a=>10, b=>20}, [10, 20]);'
          . 'push $z, 30;'
          . '(join ":", keys $x) . (join ":", sort keys $y) . "@$z"',
          '0:1:2a:b10 20 30' ],
        [ '^GLOBAL_PHASE',
          '${^GLOBAL_PHASE}', 'RUN'],
        [ '\o',
          '"\o{10}"', chr 8 ],
        [ 'package-block',
          'package My::Number { sub eleven { 11 } } My::Number::eleven()',
          11 ],
        [ 'srand-return',
          'srand 42', 42 ],
        [ 'prototype+',
          'sub proto_plus (+) { $_[0][0] }; my @ar = qw( a b ); proto_plus(@ar)',
          'a' ],
    ],

    '5.012' => [
        [ 'package-version',
          'package Local::V 4.3; 1', 1],
        [ '...',
          'my $x = 0; if ($x) { ... } else { 1 }', 1],
        [ 'each-array',
          'my $r; my @x = qw(a b c); while (my ($i, $v) = each @x) '
          . ' { $r .= $i . $v; } $r', '0a1b2c'],
        [ 'keys-array',
          'my @x = qw(a b c); join q(), keys @x', '012'],
        [ 'values-array',
          'my @x = qw(a b c); join q(), values @x', 'abc'],
        [ 'delete-local',
          'our %x = (a=>10, b=>20); {delete local $x{a};'
          . ' die if exists $x{a}};$x{a}', 10],
        [ 'length-undef',
          'length undef', undef],
        [ '\N',
          '"\n" !~ /\N/', 1],
        [ 'while-readdir',
          join(' ',
               'use FindBin; use File::Spec;',
               'opendir my $DIR, $FindBin::Bin or die $!;',
               'my $c = 0;',
               '$_ eq ("File::Spec"->splitpath($0))[-1]',
               'and ++$c while readdir $DIR;',
               '$c'),
          1 ],
    ],

    '5.010' => [
        [ '//',
          'undef // 1', 1],
        [ '?PARNO',
          '"abad" =~ /^(.).(?1).$/', 1],
        [ '?<>',
          '"a1b1" =~ /(?<b>.)b\g{b}/;', 1],
        [ '?|',
          '"abc" =~ /(?|(x)|(b))/ ? $1 : undef', 'b'],
        [ 'quant+',
          '"xaabbaa" =~ /a*+a/;', q()],
        [ 'regex-verbs',
          'my @r = ("AC" =~ /^A(*THEN)B|.C/g); "@r"', 'AC' ],
        [ '\K',
          '(my $x = "abc") =~ s/a\Kb/B/; $x', 'aBc'],
        [ '\R',
          'grep $_ =~ /^\R$/, "\x0d", "\x0a", "\x0d\x0a"', 3],
        [ '\v',
          '"\r" =~ /\v/ ? 1 : 0', 1 ],
        [ '\h',
          '"\t" =~ /\h/ ? 1 : 0', 1 ],
        [ '\gN',
          '"aba" =~ /(a)b\g{1}/;', 1],
        [ 'readline()',
          'local *ARGV = *DATA{IO}; chomp(my $x = readline()); $x',
          'readline default' ],
        [ 'stack-file-test',
          '-e -f $^X', 1],
        [ 'recursive-sort',
          'sub re {$a->[0] <=> $b->[0] '
          . 'or re(local $a = [$a->[1]], local $b = [$b->[1]])}'
          . 'join q(), map @$_, sort re ([1,2], [1,1], [2,1], [2,0])',
          '11122021',
          MAY_WORK_IN_OLDER ],  # Was probably just a documentation fix.
        [ '/p',
          '"abc" =~ /b/p;${^PREMATCH}', 'a'],
        [ 'lexical-$_',
          '$_ = 7; { my $_ = 42; } $_ ', 7 ],
    ],
    '5.008001' => [
        [ 's-utf8-delimiters-hack',
          eval q{qq{ my \$string = "a"; use utf8; \$string =~ s\N{U+2759}a\N{U+2759}\N{U+2759}b\N{U+2759}; \$string }}, 'b' ],
    ],
);

my $count = 0;

for my $version (keys %tests) {
    my $vf = sprintf '%.3f', $version;
    my @triples = @{ $tests{$version} };
    my $can = eval { require ( 0 + $version) };
    $count += 2 * @triples;
    for my $triple (@triples) {
        my $removed = Syntax::Construct::removed($triple->[0]);
        my $value = eval "use Syntax::Construct qw($triple->[0]);$triple->[1]";
        my $err = $@;
        if ($can) {
            if ($err) {
                ok($removed, 'removed in version');
                like($err, qr/\Q$triple->[0] removed in $removed/);

            } else {
                is($err, q(), "no error $triple->[0]");
                if (! defined $value || 'SKIPPED' ne $value) {
                    is($value, $triple->[2], $triple->[0]);
                }
                if ($removed) {
                    cmp_ok($removed, '>', $],
                           $triple->[0]
                               . ' not removed in the current version');
                    ++$count;
                }
            }

        } else {
            like($err,
                 qr/^Unsupported construct \Q$triple->[0]\E at \(eval [0-9]+\) line 1 \(Perl $vf needed\)\n/,
                 $triple->[0]);
            my $value = eval "$triple->[1]";
            if (($value || "") ne 'SKIPPED'
                && ($triple->[3] || "") ne MAY_WORK_IN_OLDER
            ) {
                isnt($value, $triple->[2], "not $triple->[0]");
            } else {
                --$count unless 'SKIPPED' eq $value;
            }
        }
    }
}

done_testing($count) if $can_have_plan;


__DATA__
readline default

=for completness
    '5.014' => [
        [ '/l',
        [ '/d',
    '5.020' => [
        [ 'utf8-locale',
    old => [
        [ '??',       # see 04-extra.t
        [ 'for-qw',   # see 04-extra.t
        [ '@_=split', # see 04-extra.t
=cut

