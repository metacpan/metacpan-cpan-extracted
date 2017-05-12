use strict;
use warnings;
use Test::Fixme 0.14;
use Test::More;

run_tests(
  filename_match => qr/\.(pm|pl)$/i,
  match => qr/(FIXME|TODO)/,
  where => [ qw( lib t Makefile.PL ) ],
  warn  => 1,
);
