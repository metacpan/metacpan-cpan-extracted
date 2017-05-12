use strict;
use warnings;

use Test::More;

{
  package My::Class;
  use Moose;
  use MooseX::RememberHistory;

  has 'x' => ( 
    traits => [ RememberHistory ],
    isa    => 'Num', 
    is     => 'rw' 
  );

  package My::Class::Position;
  use Moose;
  extends 'My::Class';
  has '+x' => (history_getter => 'position_history');
}

{
  my $obj = My::Class->new;
  isa_ok($obj, 'My::Class');
  can_ok($obj, 'x');

  ok( $obj->meta->get_attribute('x')->does('RememberHistory'), "Does RememberHistory");
  can_ok($obj, 'x_history');
  is_deeply($obj->x_history, [], 'history starts empty');

  $obj->x(1);
  is($obj->x, 1, 'getter-setters work');
  is_deeply($obj->x_history, [ 1 ], 'history appended');
}

{
  my $obj = My::Class->new( x => 2 );
  is( $obj->x, 2, "Initial value exists" );
  $obj->x(3);
  is_deeply( $obj->x_history, [ 2, 3 ], "Initial value also exists in history" );
}

{
  my $obj = My::Class::Position->new;
  isa_ok($obj, 'My::Class');
  can_ok($obj, 'x');
  can_ok($obj, 'position_history');
}

done_testing;

