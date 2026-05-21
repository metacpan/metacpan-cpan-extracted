use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( :cmXXXX );
  use_ok 'TUI::Views::CommandSet';
  use_ok 'TUI::Views::View';
}

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test the commandEnabled method
subtest 'commandEnabled method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok(
    $view->commandEnabled( cmCancel ), 
    'commandEnabled method returns true'
  );
};

# Test the disableCommands method
subtest 'disableCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->disableCommands( $commands ) }
    'disableCommands method executed without errors';
};

# Test the enableCommands method
subtest 'enableCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->enableCommands( $commands ) }
    'enableCommands method executed without errors';
};

# Test the disableCommand method
subtest 'disableCommand method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->disableCommand( cmCancel ) }
    'disableCommand method executed without errors';
  ok(
    !$view->commandEnabled( cmCancel ),
    'commandEnabled method returns false'
  );
};

# Test the enableCommand method
subtest 'enableCommand method' => sub {
  my $view = TView->new( bounds => $bounds );
  ok(
    !$view->commandEnabled( cmZoom ),
    'commandEnabled method returns false'
  );
  lives_ok { $view->enableCommand( cmZoom ) }
    'enableCommand method executed without errors';
  ok(
    $view->commandEnabled( cmZoom ),
    'commandEnabled method returns true'
  );
};

# Test the getCommands method
subtest 'getCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->getCommands( $commands ) }
    'getCommands method executed without errors';
};

# Test the setCommands method
subtest 'setCommands method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->setCommands( $commands ) }
    'setCommands method executed without errors';
};

# Test the setCmdState method
subtest 'setCmdState method' => sub {
  my $view     = TView->new( bounds => $bounds );
  my $commands = TCommandSet->new();
  lives_ok { $view->setCmdState( $commands, !!1 ) }
    'setCmdState method executed without errors';
};

# Test the endModal method
subtest 'endModal method' => sub {
  my $view = TView->new( bounds => $bounds );
  lives_ok { $view->endModal( 256 ) }
    'endModal method executed without errors';
};

# Test the execute method
subtest 'execute method' => sub {
  my $view = TView->new( bounds => $bounds );
  is( $view->execute(), cmCancel, 'execute method returns cmCancel' );
};

done_testing();
