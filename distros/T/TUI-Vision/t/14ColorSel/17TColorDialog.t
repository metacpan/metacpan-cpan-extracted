use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::Const', qw( evBroadcast );
  use_ok 'TUI::ColorSel::Const', qw( cmNewColorItem );
  use_ok 'TUI::ColorSel::ColorDialog';
  use_ok 'TUI::ColorSel::ColorGroup';
  use_ok 'TUI::ColorSel::ColorItem';
  use_ok 'TUI::Views::Palette';
}

my $groups;
my $dlg;

subtest 'Create groups' => sub {
  lives_ok {
    $groups =
      new_TColorGroup( 'Calendar' )
      + new_TColorItem( 'Frame passive', 16 )
      + new_TColorItem( 'Frame active',  17 )
      + new_TColorItem( 'Normal text',   21 );
  } 'group hierarchy created';
};

subtest 'Object creation' => sub {
  lives_ok {
    $dlg = TColorDialog->new(
      pal    => undef,
      groups => $groups,
    );
  } 'TColorDialog object created';
  isa_ok( $dlg, TColorDialog() );

  my $obj;
  lives_ok {
    $obj = new_TColorDialog( undef, $groups );
  } 'from() lives';
  isa_ok( $obj, TColorDialog() );
};

subtest 'handleEvent(cmNewColorItem) survives' => sub {
  my $event = TEvent->new(
    what     => evBroadcast,
    command  => cmNewColorItem,
    infoByte => 0,
  );
  lives_ok { $dlg->handleEvent( $event ) }
    'handleEvent(cmNewColorItem) lives';
};

subtest 'setData/getData roundtrip' => sub {
  my $pal = TPalette->new( data => "\x00" x 22, size => 22 );
  my @in = ( $pal );
  my @out;

  is( $dlg->dataSize(), 1, 'dataSize returns 1' );
  lives_ok { $dlg->setData(\@in)  } 'setData lives';
  lives_ok { $dlg->getData(\@out) } 'getData lives';
  isa_ok( $out[0], ref($pal) );
};

done_testing;
