#!perl
use v5.20.0;
use warnings;
use utf8;

use experimental qw( signatures );

use lib 'lib';

use Test::Deep ':v1';
use Test::More;

use String::Switches qw(parse_switches canonicalize_names);

sub switches_ok ($input, $want, $desc = undef) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my @rv = parse_switches($input);

  my $ok = is_deeply(
    \@rv,
    [ $want, undef ],
    $desc // "$input -> OK",
  );

  diag explain [ @rv ] unless $ok;

  return $ok;
}

sub switches_fail ($input, $want, $desc = undef) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $have = [ parse_switches($input) ];
  cmp_deeply(
    $have,
    [ undef, $want ],
    $desc // "$input -> $want",
  ) or diag explain($have);
}

switches_ok(
  "/foo bar /baz /buz",
  [
    [ foo => 'bar' ],
    [ baz =>       ],
    [ buz =>       ],
  ],
);

switches_ok(
  "/foo bar /foo /foo /foo baz",
  [
    [ foo => 'bar' ],
    [ foo =>       ],
    [ foo =>       ],
    [ foo => 'baz' ],
  ],
);

switches_ok(
  qq{/foo one two /buz},
  [
    [ foo => "one", "two" ],
    [ buz =>       ],
  ],
);

switches_ok(
  qq{/foo one   two  /buz    },
  [
    [ foo => "one", "two" ],
    [ buz =>       ],
  ],
);

switches_ok(
  qq{},
  [ ],
  "you can parse an empty string as switches",
);

switches_ok(
  qq{/foo "hunter/killer" program /buz},
  [
    [ foo => "hunter/killer", "program" ],
    [ buz =>       ],
  ],
);

switches_fail(
  "foo /bar /baz /buz",
  "text with no switch",
);

my $B = "\N{REVERSE SOLIDUS}";

# Later, we will add support for qstrings. -- rjbs, 2019-02-04
switches_ok(
  qq{/foo "bar $B"baz" /buz},
  [
    [ foo => q{bar "baz} ],
    [ buz =>       ],
  ],
);

# Later, qstrings will allow embedded slashes, and maybe we'll allow them
# anyway if they're inside words.  For now, ban them. -- rjbs, 2019-02-04
switches_fail(
  qq{/foo hunter/killer program /buz},
  "unquoted arguments may not contain slash",
);

switches_fail(
  qq{/foo one two /buz /},
  "bogus input: / with no command!",
  "we can't end with a bare slash",
);

{
  my ($switches, $error) = parse_switches("/f b /b f /foo /bar /foo bar");
  canonicalize_names($switches, { f => 'foo', b => 'bar' });

  is_deeply(
    $switches,
    [
      [ foo => 'b' ],
      [ bar => 'f' ],
      [ foo =>       ],
      [ bar =>       ],
      [ foo => 'bar' ],
    ],
    "switch aliases and canonicalization",
  );
}

done_testing;
