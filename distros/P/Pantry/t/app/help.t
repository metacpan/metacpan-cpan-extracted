use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

use lib 't/lib';
use TestHelper;

my @untargeted= qw(
  init
);

my @targeted = qw(
  apply
  delete
  edit
  rename
  show
  strip
  sync
);

my @type_target_only = qw(
  list
);

for my $c ( @untargeted ) {
  subtest "$c help style" => sub {
    my $result = _try_command("help", $c);
    unlike( $result->output, qr/TARGET/, "Should not have TARGET section" );
  };
}

for my $c ( @targeted ) {
  subtest "$c help style" => sub {
    my $result = _try_command("help", $c);
    like( $result->output, qr/Valid TARGET types include:/s, "Should have TARGET section" );
  };
}

for my $c ( @type_target_only ) {
  subtest "$c help style" => sub {
    my $result = _try_command("help", $c);
    like( $result->output, qr/Valid types include:/s, "Should have types selection section" );
  };
}

for my $c ( @untargeted, @targeted ) {
  subtest "$c: help vs --help" => sub {
    my $result1 = _try_command("help", $c);
    my $result2 = _try_command($c, "--help");
    is( $result1->output, $result2->output, "help text matches" );
    is( $result1->exit_code, $result2->exit_code, "exit codes match" );
  };
}

done_testing;
#
# This file is part of Pantry
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
