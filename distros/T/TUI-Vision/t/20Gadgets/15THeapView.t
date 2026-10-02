use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets::HeapView';
}

{
  package MyHeapView;
  use TUI::toolkit;
  extends 'TUI::Gadgets::HeapView';
  sub BUILD     { shift->{heapStr} = 'test' }
  sub writeLine { ::pass 'writeLine()'  }
  sub drawView  { ::pass 'drawView()' }
  $INC{"MyHeapView.pm"} = 1;
}

my $view;
subtest 'THeapView->new()' => sub {
  require_ok( 'MyHeapView' );
  $view = MyHeapView->new( bounds => TRect->new() );
  isa_ok( $view, THeapView );
};

subtest 'draw()' => sub {
  can_ok( $view, 'draw' );
  lives_ok { $view->draw() } 'draw() does not die';
};

subtest 'update()' => sub {
  can_ok( $view, 'update' );
  lives_ok {
    $view->{newMem} = 0;
    $view->{oldMem} = 1;    # force branch where drawView() is called
    $view->update();
  } 'update() does not die';
};

subtest 'heapSize()' => sub {
  my $ret;
  lives_ok {
    $ret = $view->heapSize();
    ok( defined $ret, 'heapSize() returns something' );
    like( $ret, qr/^-?\d+$/, 'heapSize() returns numeric' );
  } 'heapSize() does not die';
  diag( "heapSize() returns -1 on ", $^O ) if ( $ret // 0 ) == -1;
}; #/ 'heapSize' => sub

subtest 'fields' => sub {
  ok( $view->{heapStr}, "'heapStr' is defined and not empty" );
  isnt( $view->{heapStr}, 'test', "'heapStr' has a new value" );
};

done_testing();
