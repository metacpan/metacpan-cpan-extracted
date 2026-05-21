use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the writeBuf method
subtest 'writeBuf method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $buf  = [];
  lives_ok { $view->writeBuf( 0, 0, 10, 10, $buf ) }
    'writeBuf method executed without errors';
};

# Test the writeChar method
subtest 'writeChar method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->writeChar( 0, 0, 'A', 1, 10 ) }
    'writeChar method executed without errors';
};

# Test the writeLine method
subtest 'writeLine method' => sub {
  my $view = TView->new( bounds => $bounds );
  my $buf  = [];
  lives_ok { $view->writeLine( 0, 0, 10, 10, $buf ) }
    'writeLine method executed without errors';
};

# Test the writeStr method
subtest 'writeStr method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->writeStr( 0, 0, 'Hello', 1 ) }
    'writeStr method executed without errors';
};

# Test the owner method
subtest 'owner method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok( !$view->owner(), 'owner method returns undef' );
};

# Test the shutDown method
subtest 'shutDown method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->shutDown() }
    'shutDown method executed without errors';
};

done_testing();
