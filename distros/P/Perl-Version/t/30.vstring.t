#!/usr/bin/perl

use strict;
use warnings;
use Perl::Version;
use Test::More tests => 6;

SKIP: {
  skip 'cannot test bare v-strings with Perl < 5.8.1', 6
   if $] < 5.008_001;

  my $ver = eval { Perl::Version->new( v1.2.3 ) };
  unless ( ok !$@, 'vstring parses without error' ) {
    diag( "Error: $@\n" );
  }

  is $ver, 'v1.2.3', 'vstring parses correctly';

  $ver = eval { Perl::Version->new( 1.2.3 ) };
  unless ( ok !$@, 'naked vstring parses without error' ) {
    diag( "Error: $@\n" );
  }

  is $ver, 'v1.2.3', 'naked vstring parses correctly';

  $ver = eval { Perl::Version->new( 49.50.51 ) };
  unless ( ok !$@, 'naked vstring, ascii digits parses without error' )
  {
    diag( "Error: $@\n" );
  }

  is $ver, 'v49.50.51', 'naked vstring, ascii digits parses correctly';
}
