#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use String::TagString;

my @tagstrings = (
  [ ''                   => {} ],
  [ 'foo'                => { foo => undef } ],
  [ 'foo bar'            => { foo => undef, bar => undef } ],
  [ '@foo bar'           => { '@foo' => undef, bar => undef } ],
  [ 'foo+bar'            => { foo => undef, bar => undef } ],
  [ 'foo baz:peanut bar' => { foo => undef, bar => undef, baz => 'peanut' } ],
  [ 'foo baz: bar'       => { foo => undef, bar => undef, baz => ''       } ],
  [ 'bad()tag foo bar'   => undef ],
  [ 'bad:tag|value foo'  => undef ],

  [ 'foo foo'            => { foo => undef } ],
  [ 'foo foo:'           => undef ],
  [ 'foo:1 foo:1'        => { foo => 1     } ],
  [ 'foo:1 foo:2',       => undef ],

  [ 'foo baz:"peanut butter" bar  '  => { foo => undef, bar => undef, baz => 'peanut butter' } ],
  [ 'foo+baz:"peanut butter"+bar  '  => { foo => undef, bar => undef, baz => 'peanut butter' } ],
  [ 'foo baz:"peanut\"butter" bar  ' => { foo => undef, bar => undef, baz => 'peanut"butter' } ],
  [ '"peanut butter":chunky salty  ' => { q{peanut butter} => 'chunky', salty => undef } ],

  [ 'foo baz:"peanut butter\" bar  '  => undef ],

  [ q{"foo\\"bar\\\\"} => { 'foo\\"bar\\\\' => undef } ],
);

for (@tagstrings) {
  my ($string, $expected_tags) = @$_;

  my $tags = eval { String::TagString->tags_from_string($string); };

  is_deeply(
    $tags,
    $expected_tags,
    "tags from <$string>" . (! defined $expected_tags ? ' (invalid)' : ''),
  ) or diag explain $tags;
}

my @tags = (
  [ { }                                             => ''                   ],
  [ { foo => undef }                                => 'foo'                ],
  [ [ ]                                             => ''                   ],
  [ [ 'foo' ]                                       => 'foo'                ],
  [ [ undef ]                                       => undef                ],
  [ { foo => undef, bar => undef }                  => 'bar foo'            ],
  [ { foo => undef, bar => undef, baz => undef    } => 'bar baz foo'        ],
  [ { foo => undef, bar => undef, baz => ''       } => 'bar baz: foo'       ],
  [ { foo => undef, bar => undef, baz => 'peanut' } => 'bar baz:peanut foo' ],
  [ { foo => undef, bar => "peanut butter"        } => 'bar:"peanut butter" foo' ],

  [ { 'peanut"butter'   => 'chunky' } => '"peanut\"butter":chunky' ],

  # The input has a slash and a quote, so we expect \\ (slash) then \" (quote)
  [ { 'peanut\\"butter' => 'lumpy'  } => '"peanut\\\\\"butter":lumpy' ],

  # The literal value ends in a slash, so we need to end in a double slash
  [ { 'peanut butter\\' => 'creamy' } => '"peanut butter\\\\":creamy' ],
);

for (@tags) {
  my ($tags, $want) = @$_;

  my $string = eval { String::TagString->string_from_tags($tags); };

  my $txt = defined $want ? "<$want>" : '(undef)';

  is_deeply(
    $string,
    $want,
    "$txt from tags",
  );
}
