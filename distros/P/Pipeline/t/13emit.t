#!/usr/bin/perl

use strict;
use warnings;
BEGIN {
  eval "use IO::String";
  require Test::More;
  if ($@) {
    Test::More->import( skip => 'IO::String not installed' );
  } else {
    require IO::String;
    Test::More->import( no_plan => 1 );
  }
}

my $fh = IO::String->new();
*STDERR = $fh;
use_ok( 'Pipeline::Base' );
ok( my $thing = Pipeline::Base->new() );
ok( $thing->debug( 1 ) );
ok( $thing->emit("test") );
ok( my $stringref = $fh->string_ref );
ok( $$stringref =~ /test/ );

1;


