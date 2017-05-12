use strict;
use warnings;

use Test::More;

# FILENAME: 02_immutable.t
# CREATED: 24/03/12 00:22:02 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test immutability of inc

use Path::ScanINC;

my @pre_inc = [@INC];

my @incs = ();

{
  push @incs, Path::ScanINC->new();

  unshift @INC, 'FAKE/1';

  push @incs, Path::ScanINC->new( immutable => 1 );

  unshift @INC, 'FAKE/2';

  push @incs, Path::ScanINC->new( inc => \@INC );

  unshift @INC, 'FAKE/3';

  push @incs, Path::ScanINC->new( inc => \@INC, immutable => 1 );

  unshift @INC, 'FAKE/4';
}

pass("Setup 4 instances with various values of \\\@INC");

is_deeply( [ $incs[0]->inc ], [ $incs[2]->inc ], 'Both non-immutable incs are the same' );

use List::Util qw( first );

sub grepn {
  my ( $what, $is, $item ) = @_;
  if ($is) {
    isnt( ( scalar first { $_ eq $what } $incs[$item]->inc ), undef, "$what found in i=$item" );
  }
  else {
    is( ( scalar first { $_ eq $what } $incs[$item]->inc ), undef, "$what not found in i=$item" );
  }
}

sub t_immute {
  my ( $is, $item ) = @_;
  if ($is) {
    ok( $incs[$item]->immutable, "i=$item is immutable" );
  }
  else {
    ok( !$incs[$item]->immutable, "i=$item is not immutable" );
  }
}

subtest "Test Immutability bits" => sub {
  t_immute( 1, $_ ) for 1, 3;
  t_immute( 0, $_ ) for 0, 2;
};

subtest "FAKE/1 in all" => sub {
  my $x = 'FAKE/1';
  grepn( $x, 1, $_ ) for 0 .. 3;
};

subtest "FAKE/2 not in i=1" => sub {
  my $x = 'FAKE/2';
  grepn( $x, 1, $_ ) for 0, 2 .. 3;
  grepn( $x, 0, $_ ) for 1;
};

subtest "FAKE/3 not in i=1" => sub {
  my $x = 'FAKE/3';
  grepn( $x, 1, $_ ) for 0, 2 .. 3;
  grepn( $x, 0, $_ ) for 1;
};

subtest "FAKE/4 not in i=1,i=3" => sub {
  my $x = 'FAKE/4';
  grepn( $x, 1, $_ ) for 0, 2;
  grepn( $x, 0, $_ ) for 1, 3;
};

done_testing;

