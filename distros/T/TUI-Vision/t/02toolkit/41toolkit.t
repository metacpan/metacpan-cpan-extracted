use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  require_ok 'UNIVERSAL::Object';
  use_ok 'Devel::StrictMode';
  use_ok 'TUI::toolkit', qw( /^is_/ signature assert );
}

BEGIN {
  package Export::Ok;
  use Scalar::Util qw( blessed );
  use TUI::toolkit;
  assert ( TUI::toolkit::is_Moos );
  $INC{"Export/Ok.pm"} = 1;
}

BEGIN {
  package Point;
  use TUI::toolkit;
  has x => ( is => 'bare' );
  has y => ( is => 'rw' );
  sub x {
    $#_ ? $_[0]->{x} = $_[1] : $_[0]->{x}
  }
  sub DEMOLISH { ::pass __PACKAGE__ . '::DEMOLISH called'  }
  no TUI::toolkit;
  $INC{"Point.pm"} = 1;
}

BEGIN {
  package Point3D;
  use TUI::toolkit;                # should NOT replace our dump
  extends 'Point';
  has z => ( is => 'rw' );
  sub dump { return "custom" }    # class provides dump
  sub DEMOLISH { ::pass __PACKAGE__ . '::DEMOLISH called'  }
  no TUI::toolkit;
  $INC{"Point3D.pm"} = 1;
}

use_ok 'Export::Ok';
use_ok 'Point';
use_ok 'Point3D';

note "Toolkit is $TUI::toolkit::name";

subtest 'Import' => sub {
  ok( main->can('is_UNIVERSAL'), 'symbol is_UNIVERSAL exists' );
  ok( main->can('signature'), 'signature is imported' );
  ok is_UNIVERSAL(), 'is_UNIVERSAL is set to true';

  ok( Export::Ok->can( 'blessed' ), 'blessed was not deleted' );
  ok( !Export::Ok->can( 'confess' ), 'confess was not imported' );
  can_ok( 'Export::Ok', $_ ) for qw( true false has extends signature );
};

subtest 'Point' => sub {
  plan tests => 6 + 1;
  my $point = Point->new( x => 2, y => 3 );
  isa_ok( $point, 'Point', 'Object is of class Point' );
  is_deeply( $point, { x => 2, y => 3 }, 'point is set correctly' );
  can_ok( $point, 'dump' );
  can_ok( $point, $_ ) for qw( x y );
  ok( !Point->can( 'z' ), "!Point->can('z')" );
};

subtest 'Point3D' => sub {
  plan tests => 7 + 2;
  my $point = Point3D->new( x => 1, y => 2, z => 3 );
  isa_ok( $point, 'Point3D', 'Object is of class Point3D' );
  is_deeply( $point, { x => 1, y => 2, z => 3 }, 'point is set correctly' );
  can_ok( $point, 'dump' );
  can_ok( $point, $_ ) for qw( x y z );
  is( $point->dump(), "custom", 'existing dump method preserved' );
};

subtest 'create_method redefine warns' => sub {
  my $warning;
  {
    local $SIG{__WARN__} = sub { $warning = shift };
    TUI::toolkit::_create_method( 'Point3D', 'z', sub { 2 } );
  }
  like(
    $warning, qr/Subroutine Point3D::z redefined/,
    'Perl redefine warning triggered'
  );
};

subtest 'assert' => sub {
  no TUI::toolkit;
  use TUI::toolkit qw( assert );
  lives_ok { assert( 1 == 1 ) } 'assert does not die on true condition';
  SKIP: {
    skip "Strict mode causes assert to die on false condition", 1 unless STRICT;
    throws_ok { assert( 1 == 0 ) } qr/Assertion failed/, 
      'assert dies on false condition';
  }
};

done_testing();
