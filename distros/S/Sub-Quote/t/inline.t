use strict;
use warnings;
no warnings 'once';
use Test::More;
use Test::Fatal;
use Data::Dumper;

use Sub::Quote qw(
  capture_unroll
  inlinify
);

my $captures = {
  '$x' => \1,
  '$y' => \2,
};
my $prelude = capture_unroll '$captures', $captures, 4;
my $out = eval
  $prelude
  . '[ $x, $y ]';
is "$@", '', 'capture_unroll produces valid code';
is_deeply $out, [ 1, 2 ], 'unrolled variables get correct values';

like exception {
  capture_unroll '$captures', { '&foo' => \sub { 5 } }, 4;
}, qr/^capture key should start with @, % or \$/,
  'capture_unroll rejects vars other than scalar, hash, or array';

{
  my $inlined_code = inlinify q{
    my ($x, $y) = @_;

    [ $x, $y ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2 ], 'inlinified code get correct values';
  unlike $inlined_code, qr/my \(\$x, \$y\) = \@_;/,
    "matching variables aren't reassigned";
}

{
  $Bar::baz = 3;
  my $inlined_code = inlinify q{
    package Bar;
    my ($x, $y) = @_;

    [ $x, $y, our $baz ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2, 3 ], 'inlinified code get correct values';
  unlike $inlined_code, qr/my \(\$x, \$y\) = \@_;/,
    "matching variables aren't reassigned";
}

{
  my $inlined_code = inlinify q{
    my ($d, $f) = @_;

    [ $d, $f ];
  }, '$x, $y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify with unmatched params produces valid code'
    or diag "code:\n$inlined_code";
  is_deeply $out, [ 1, 2 ], 'inlinified code get correct values';
}

{
  my $inlined_code = inlinify q{
    my $z = $_[0];
    $z;
  }, '$y', $prelude;
  my $out = eval $inlined_code;
  is "$@", '', 'inlinify with out @_ produces valid code'
    or diag "code:\n$inlined_code";
  is $out, 2, 'inlinified code get correct values';
}

done_testing;
