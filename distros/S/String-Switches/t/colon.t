#!perl
use v5.20.0;
use warnings;
use utf8;

use experimental qw( signatures );

use lib 'lib';

use Test::Deep ':v1';
use Test::More;

use String::Switches qw(parse_colonstrings);

sub colons_ok ($input, $arg, $want, $desc = undef) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $rv = parse_colonstrings($input, $arg);

  my $ok = is_deeply(
    $rv,
    $want,
    $desc // "$input -> OK",
  );

  diag explain $rv unless $ok;

  return $ok;
}

sub colons_fail ($input, $arg, $want, $desc = undef) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $rv = parse_colonstrings($input, $arg);

  is($rv, undef, "$input -> error");
}

my $common_arg = {
  fallback => sub ($text_ref) {
    ((my $token), $$text_ref) = split /\s+/, $$text_ref, 2;
    return [ literal => $token ];
  },
};

colons_ok(
  q{foo:bar baz quux:"Trail Mix"},
  $common_arg,
  [
    [ foo     => 'bar' ],
    [ literal => 'baz' ],
    [ quux    => 'Trail Mix' ],
  ],
);

colons_ok(
  q{foo:bar baz quux:"Trail Mix"},
  { literal => 'xyzzy' },
  [
    [ foo     => 'bar' ],
    [ xyzzy   => 'baz' ],
    [ quux    => 'Trail Mix' ],
  ],
);

done_testing;
