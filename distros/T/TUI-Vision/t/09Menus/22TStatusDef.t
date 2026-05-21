use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Menus::StatusItem';
  use_ok 'TUI::Menus::StatusDef';
}

my $add_status_def = sub { goto &TUI::Menus::StatusDef::_add_status_def };
my $add_status_item = sub { goto &TUI::Menus::StatusDef::_add_status_item };

# Test object creation
my $s1 = new_TStatusDef( 1, 1 );
isa_ok( $s1, TStatusDef, 'Object is of class TStatusDef' );

my $s2 = new_TStatusDef( 2, 2 );
isa_ok( $s2, TStatusDef, 'Object is of class TStatusDef' );

my $s3 = TStatusDef->new( min => 3, max => 3 );
isa_ok( $s3, TStatusDef, 'Object is of class TStatusDef' );

# Test &$add_status_item method
can_ok( $s1, '_add_status_item' );
my $i1 = new_TStatusItem( 'One', 0x1234, 1 );
my $i2 = new_TStatusItem( 'Two', 0x2345, 2 );
isa_ok( $i1, TStatusItem, 'Object is of class TStatusItem' );
isa_ok( $i2, TStatusItem, 'Object is of class TStatusItem' );
lives_ok { 
  $s1->$add_status_item( $i1 )->$add_status_item( $i2 );
} "TStatusItem's correctly added to TStatusDef";
is( 
  $s1->{items}{next}, 
  $i2,
 'Second TStatusItem correctly added to TStatusDef'
);

# Test &$add_status_def method
can_ok( $s2, '_add_status_def' );
$s1->$add_status_def( $s3 );
is( $s1->{next}, $s3, 'TStatusDef correctly added to TStatusDef' );

my $status_def;
lives_ok {
  $status_def =
    new_TStatusDef( 0, 1 ) +
      new_TStatusItem( "One", 0x1000, 1 ) +
    new_TStatusDef( 2, 3 ) +
      new_TStatusItem( "Two", 0x2000, 2 ) +
      new_TStatusItem( "Three", 0x3000, 2 );
} 'operator "+" adds status items correctly';
isa_ok( $status_def, TStatusDef, 'Object is of class TStatusDef' );
isa_ok( $status_def->{next}, TStatusDef, 'TStatusDef correctly added' );
isa_ok( $status_def->{items}, TStatusItem, 'TStatusItem correctly added' );

done_testing();
