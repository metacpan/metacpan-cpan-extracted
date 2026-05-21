use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw( refaddr );

BEGIN {
  use_ok 'TUI::Drivers::Event';
}
use_ok 'MessageEvent';

# Test object creation
my $event = MessageEvent->new(
  command => 1,
  infoPtr => \my $var,
);
isa_ok( $event, 'MessageEvent', 'Object is of class MessageEvent' );

# Test command field
is( $event->{command}, 1, 'command field is set correctly' );
$event->{command} = 2;
is( $event->{command}, 2, 'command field is updated correctly' );

# Test infoPtr field
is( $event->{infoInt}, refaddr( \$var ), 'infoInt field is fetched correctly' );
is( refaddr( $event->{infoPtr} ), refaddr( \$var ),
  'infoPtr field is set correctly' );
my $new_var;
$event->{infoPtr} = \$new_var;
is( refaddr( $event->{infoPtr} ), refaddr( \$new_var ),
  'infoPtr field is updated correctly' );
$event->{infoPtr} = 'non-ref';
is( $event->{infoInt}, 0, 'infoPtr field handling non references correctly' );

# Test infoLong field
$event = MessageEvent->new( infoLong => 0x12345678 );
is( $event->{infoLong}, 0x12345678, 'infoLong field is set correctly' );
$event->{infoLong} = 0x87654321;
is( $event->{infoLong}, 0x87654321, 'infoLong field is updated correctly' );

# Test infoWord field
$event = MessageEvent->new( infoWord => 0x1234 );
is( $event->{infoWord}, 0x1234, 'infoWord field is set correctly' );
$event->{infoWord} = 0x5678;
is( $event->{infoWord}, 0x5678, 'infoWord field is updated correctly' );

# Test infoInt field
$event = MessageEvent->new( infoWord => 42 );
is( $event->{infoInt}, 42, 'infoInt field is set correctly' );
$event->{infoInt} = 84;
is( $event->{infoInt}, 84, 'infoInt field is updated correctly' );
is( $event->{infoPtr}, 84, 'infoPtr field is fetched correctly' );

# Test infoByte field
$event = MessageEvent->new( infoByte => 0x12 );
is( $event->{infoByte}, 0x12, 'infoByte field is set correctly' );
$event->{infoByte} = 0x34;
is( $event->{infoByte}, 0x34, 'infoByte field is updated correctly' );

# Test infoChar field
$event = MessageEvent->new( infoChar => 'A' );
is( $event->{infoChar}, 'A', 'infoChar field is set correctly' );
$event->{infoChar} = 'B';
is( $event->{infoChar}, 'B', 'infoChar field is updated correctly' );

# Test exception handling for DELETE and CLEAR
throws_ok { delete $event->{command} } qr/restricted/,
  'DELETE method throws exception';
throws_ok { %$event = () } qr/restricted/,
  'CLEAR method throws exception';

done_testing();
