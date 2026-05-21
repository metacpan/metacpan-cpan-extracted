use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Views::Palette';
}

my $data = sub {
  my $res = '';
  for my $i ( 1 .. $_[0]->at(0) ) {
    $res .= chr( $_[0]->at( $i ) );
  }
  return $res;
};

my $size = sub {
  return $_[0]->at(0);
};

# Test 1: Object initialization with data and size
my $palette = TPalette->new( data => 'abcd', size => 3 );
is( $palette->$data(), 'abc', 'Data(4) initialized correctly' );
is( $palette->$size(), 3,     'Size initialized correctly' );

$palette = TPalette->new( data => 'xy', size => 3 );
is( $palette->$data(), "xy\0", 'Data(2) initialized correctly' );
is( $palette->$size(), 3,      'Size initialized correctly' );

# Test 2: Data retrieval with at
is( $palette->at( 1 ), ord( 'x' ), 'Data retrieved correctly' );
is( $palette->[2],     ord( 'y' ), '[] operator retrieved correctly' );

# Test 3: Copying an object
$palette = TPalette->new( data => 'abc', size => 3 );
my $palette_copy = TPalette->new( copy_from => $palette );
is( $palette_copy->$data(), 'abc', 'Data copied correctly' );

# Test 4: Assigning data from one object to another
my $palette_new = TPalette->new( data => '1234', size => 4 );
$palette_new->assign( $palette );
is( $palette_new->$data(), 'abc', 'Data assigned correctly' );
is( $palette_new->$size(), 3,     'Size initialized correctly' );

done_testing();
