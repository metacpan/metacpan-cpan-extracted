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
  
  ok( mkdir('roles'), "Created 'roles' directory" );
  do { open my $fh, ">", "roles/touch"; say $fh "touched"; };
  ok( -e "roles/touch", "Created 'roles/touch' file" );

  my $result = test_app( 'Pantry::App' => [qw(init)] );
  is( $result->error, undef, "Ran 'pantry init' without error" );

  for my $d ( @created_dirs ) {
    ok( -d $d, "After: $d directory exists" );
  }
  like( $result->stdout, qr/Directory 'roles' already exists/,
    "After: 'roles exists' message seen"
  );
  ok( -e "roles/touch", "File 'roles/touch' still exists" );
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
