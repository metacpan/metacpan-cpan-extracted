
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( :evXXXX );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw( :ofXXXX );
  use_ok 'TUI::Dialogs::Label';
} #/ BEGIN

# Mock link object used by TLabel
BEGIN {
  package MyLink;
  sub new {
    my ( $class, %args ) = @_;
    my $self = { %args, focused => 0 };
    return bless $self, $class;
  }
  sub focus { shift->{focused} = 1 }
  $INC{'MyLink.pm'} = 1;
} #/ BEGIN

use_ok 'MyLink';

my (
  $bounds,
  $label,
  $link,
);

# Constructor tests
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 1 );
  isa_ok( $bounds, TRect, 'bounds created as TRect' );

  lives_ok {
    $link  = MyLink->new( options => 0 );
    $label = TLabel->new(
      bounds => $bounds,
      text   => 'Test label',
      link   => $link,
    );
  } 'Constructor lives';
  isa_ok( $label, TLabel(),'Object is-a TLabel' );

  is( $label->{link},  $link, 'link attribute initialized with provided link' );
  ok( !$label->{light},       'light defaults to false' );

  ok(
    $label->{options} & ofPreProcess,
    'ofPreProcess flag is set on options'
  );
  ok(
    $label->{options} & ofPostProcess,
    'ofPostProcess flag is set on options'
  );
  ok(
    $label->{eventMask} & evBroadcast,
    'evBroadcast is set on eventMask'
  );
}; #/ 'Object creation' => sub

# Test shutDown clears link
subtest 'shutDown' => sub {
  my $link  = MyLink->new;
  my $label = TLabel->new( bounds => $bounds, text => 'Text', link => $link );
  ok( $label->{link}, 'link set before shutDown' );
  lives_ok { $label->shutDown() } 'Explicit shutDown() call lives';
ok( !defined $label->{link}, 'link cleared by shutDown' );
}; #/ 'shutDown' => sub

# Test draw
subtest 'draw' => sub {
  lives_ok { $label->draw() } 'draw() lives';
  $label->{light} = 1;    # Toggle light and call draw() again
  lives_ok { $label->draw() } 'draw() lives when light is true';
}; #/ 'draw' => sub

# Test getPalette returns palette objects
subtest 'getPalette' => sub {
  my $p;
  lives_ok { $p = $label->getPalette } 'getPalette call lives';
  ok( ref $p, 'first palette is a reference (object)' );
}; #/ 'getPalette' => sub

# Test focus link via evMouseDown
subtest 'focus link' => sub {
  $link->{options} = ofSelectable;
  $link->{focused} = 0;
  my $event = TEvent->new( what => evMouseDown );
  isa_ok( $event, TEvent, 'event is a TEvent object' );

  {
    # Prevent side effects from superclass
    no warnings;
    local *TUI::Dialogs::StaticText::handleEvent = sub { };
    lives_ok { $label->handleEvent( $event ) }
      'handleEvent(evMouseDown) lives';
  }

  ok( $link->{focused},
    'link->focus called when link is selectable on mouse down' );
  is( $event->{what}, evNothing, 'event.what set to evNothing by clearEvent' );
}; #/ 'focus link' => sub

done_testing();
