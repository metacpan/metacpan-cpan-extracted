use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

use File::pushd 1.00 qw/tempd/;
use App::Cmd::Tester;
use Pantry::App;

my @created_dirs = qw(
  cookbooks
  environments
  reports
  roles
);

{
  my $wd = tempd;
  for my $d ( @created_dirs ) {
    ok( ! -e $d, "Before: $d does not exist" );
  }

  my $result = test_app( 'Pantry::App' => [qw(init)] );
  is( $result->error, undef, "Ran without error" );

  for my $d ( @created_dirs ) {
    ok( -d $d, "After: $d directory created" );
    like( $result->stdout, qr/\Q$d\E/, "After: $d creation message seen" );
  }
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
