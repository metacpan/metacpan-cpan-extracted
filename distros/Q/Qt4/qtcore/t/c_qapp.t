use Test::More tests => 3;

use QtCore4;
use QtGui4;

$a=0;

# Test if the Qt::Application ctor works

eval { $a = Qt::Application( \@ARGV ) };

ok( !+$@, 'Qt::Application ctor' );

# Test wether the global qApp object is properly set up

eval { qApp->libraryPaths() };

ok( !+$@, 'qApp properly set up' ) or diag( $@ );

# One second test of the event loop

Qt::Timer::singleShot( 300, qApp, SLOT 'quit()' );

ok( !qApp->exec, 'One second event loop' );
