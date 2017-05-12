use strict;
use warnings;
use Test::More;
BEGIN {
  plan skip_all => 'test requires Test::Strict'
    unless eval q{ use Test::Strict; 1 };
}

all_perl_files_ok( qw( lib t Makefile.PL ) );
