#!/usr/bin/perl
use Music::Abc::DT qw( get_gchords $sym );
use Test::More tests => 1;
use strict;
use warnings;

subtest 'get_gchords' => sub {
  plan tests => 2;

  subtest 'when there\'s no input passed to get_gchords' => sub {
    my $gc = 'F';
    $sym->{text} = $gc;

    is( "$gc\n", get_gchords(), 'get_gchords() returns the gchords of the current symbol (global variable)' );
  };

  subtest 'when a symbol is passed to get_gchords' => sub {
    my $gc  = 'F';
    my $sym = { text => $gc };

    is( "$gc\n", get_gchords($sym), 'get_gchords() returns the gchords of the symbol passed as argument' );
  };
};

done_testing;
