use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Const', qw( evCommand );
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Views::Util', qw( message );
}

BEGIN {
  package MyTView;
  use TUI::toolkit;
  extends 'TUI::Views::View';
  my $toggle = 1;
  sub handleEvent {
    my ( $self, $event ) = @_;
    $self->clearEvent( $event ) if $toggle;
    $toggle = 1 - $toggle;
    return;
  }
  $INC{"MyTView.pm"} = 1;
}

use_ok 'MyTView';

# Initial setup
my $bounds = TRect->new();
isa_ok( $bounds, TRect );
my $receiver = MyTView->new( bounds => $bounds );
isa_ok( $receiver, TView );

# Test case 1: Valid Input
my $result = message( $receiver, evCommand, 2, \'info' );
isa_ok( $result, 'MyTView' );

# Test case 2: Non-evNothing Event
$result = message( $receiver, evCommand, 2, \'info' );
is( $result, undef, 'Non-evNothing event test' );

# Test case 3: Undefined Receiver
$result = message( undef, evCommand, 2, \'info' );
is( $result, undef, 'Undefined receiver test' );

done_testing();
