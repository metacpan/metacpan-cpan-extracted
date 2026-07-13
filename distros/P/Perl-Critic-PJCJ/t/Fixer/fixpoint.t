#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like mock subtest warning warns );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                       qw( lib t/lib );
use FakePolicy                ();
use Perl::Critic::PJCJ::Fixer ();
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting qw(
  desc_double
  desc_single
);

my $Fixer = Perl::Critic::PJCJ::Fixer->new;

subtest "Fixes cascade to a fixed point" => sub {
  is $Fixer->fix(q(my $x = "don\'t say \"hi\"";)),
    q[my $x = q(don't say "hi");],
    "double quotes converge to q() via single quotes";
};

subtest "Line ranges restrict fixes" => sub {
  my $in = qq(my \$a = 'one';\nmy \$b = 'two';\n);
  is $Fixer->fix($in, lines => [2, 2]),
    qq(my \$a = 'one';\nmy \$b = "two";\n), "only the requested line is fixed";
  is $Fixer->fix($in, lines => [1, 1]),
    qq(my \$a = "one";\nmy \$b = 'two';\n),
    "a different range fixes the other line";
  is $Fixer->fix($in), qq(my \$a = "one";\nmy \$b = "two";\n),
    "no range fixes everything";
};

subtest "Line ranges leave out-of-range violations untouched" => sub {
  my $in = qq(my \$a = 'one';\nuse Foo "a", "b";\nmy \$c = 'three';\n);
  is $Fixer->fix($in, lines => [2, 2]),
    qq[my \$a = 'one';\nuse Foo qw( a b );\nmy \$c = 'three';\n],
    "only the use statement line is fixed";
  is $Fixer->fix($in, lines => [3, 3]),
    qq(my \$a = 'one';\nuse Foo "a", "b";\nmy \$c = "three";\n),
    "only the trailing line is fixed";
};

subtest "Line ranges do not drift when fixes shorten the document" => sub {
  my $in = qq(use Foo "a",\n  "b";\nmy \$x = 'zzz';\n);
  is $Fixer->fix($in, lines => [1, 2]),
    qq[use Foo qw( a b );\nmy \$x = 'zzz';\n],
    "a line outside the original range is not fixed";
  my $range = [1, 2];
  $Fixer->fix($in, lines => $range);
  is $range, [1, 2], "the caller's range is not modified";
};

subtest "Oscillating fixes warn and stop early" => sub {
  my $fixer = Perl::Critic::PJCJ::Fixer->new;
  $fixer->{policy} = FakePolicy->new(flags => {
    "PPI::Token::Quote::Single" => desc_double,
    "PPI::Token::Quote::Double" => desc_single,
  });
  my $in = q(my $x = 'a';);
  my $out;
  like warning { $out = $fixer->fix($in) }, qr/oscillate/,
    "a two-state cycle is reported";
  is $out, $in, "the first revisited state is returned";
};

subtest "Non-converging fixes warn on exhaustion" => sub {
  my $mock = mock "Perl::Critic::PJCJ::Fixer",
    override => [_fix_once => sub ($self, $source, $lines) { $source . "x" }];
  my $out;
  like warning { $out = Perl::Critic::PJCJ::Fixer->new->fix("y") },
    qr/still changing after 10 passes/,
    "exhausting the pass budget is reported";
  is $out, "y" . "x" x 10, "the last state is returned";
};

subtest "Converging fixes are silent" => sub {
  is warns { $Fixer->fix(q(my $x = "don\'t say \"hi\"";)) }, 0,
    "a multi-pass convergence emits no warning";
};

subtest "Fixing is idempotent" => sub {
  my @sources = (
    q(my $x = 'hello';),
    'my $x = "user\@domain.com";',
    'my @w = qw/one two/;',
    "use Foo 'single_arg';",
    'use Qux ( key => "value" );',
    q(my $x = "don\'t say \"hi\"";),
  );
  for my $source (@sources) {
    my $once = $Fixer->fix($source);
    is $Fixer->fix($once), $once, "stable: $source";
  }
};

done_testing
