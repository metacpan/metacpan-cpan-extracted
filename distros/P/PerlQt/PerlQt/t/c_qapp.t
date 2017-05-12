BEGIN { print "1..3\n" }

use Qt;

$a=0;

# testing if the Qt::Application ctor works

eval { $a=Qt::Application(\@ARGV) };

print +$@ ? "not ok\n" : "ok 1\n";

# testing wether the global object is properly setup

eval { Qt::app()->libraryPaths() };

print +$@ ? "not ok\n" : "ok 2\n";

# one second test of the event loop

Qt::Timer::singleShot( 300, Qt::app(), SLOT "quit()" );

print Qt::app()->exec ? "not ok\n" : "ok 3\n";
