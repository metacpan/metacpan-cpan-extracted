use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Collection';
  use_ok 'TUI::Gadgets::LineCollection';
}

is(
  TLineCollection(),
  'TUI::Gadgets::LineCollection',
  'TLineCollection() returns package name'
);

my $class = TLineCollection();

subtest 'constructor' => sub {
  my $obj;
  lives_ok { $obj = $class->new( limit => 10, delta => 5 ) } 'new lives';

  isa_ok( $obj, $class );
  isa_ok( $obj, TCollection );

  is( $obj->{limit}, 10, 'limit set' );
  is( $obj->{delta}, 5, 'delta set' );
};

subtest 'BUILDARGS alias' => sub {
  my $obj;
  lives_ok { $obj = $class->new( lim => 20, delta => 7 ) } 'alias lim lives';

  is( $obj->{limit}, 20, 'limit alias works' );
  is( $obj->{delta}, 7, 'delta set' );
};

subtest 'factory constructor' => sub {
  my $obj;
  lives_ok { $obj = new_TLineCollection( 15, 3 ) } 'new_TLineCollection lives';

  isa_ok( $obj, $class );

  is( $obj->{limit}, 15, 'limit set by factory' );
  is( $obj->{delta}, 3, 'delta set by factory' );
};

done_testing();
