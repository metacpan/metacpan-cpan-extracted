use strict;
use warnings;
use Test::More 0.88;

use utf8;
use lib 't/lib';
use MLTests;
use Encode qw/encode_utf8/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $name = "®icardo Sígnes";
my $raw = encode_utf8($name);

for my $pair (
  [ file_utf8   => 't/utf8.txt' => $name            ],
  [ file_utf8   => 't/utf8.txt' => $raw => ":raw"   ],
  [ file_raw    => 't/utf8.txt' => $raw             ],
) {
  my ($suffix, $file, $expected, $enc) = @$pair; 
  my $options = $enc ? { binmode => $enc } : undef;
  my $method = "read_$suffix";
  is_deeply(
    MLTests->$method(( $options ? $options : () ), $file),
    { author => $expected },
    $enc ? "$method (with $enc)" : $method,
  );
}

done_testing;
# vim: ts=2 sts=2 sw=2 et:
