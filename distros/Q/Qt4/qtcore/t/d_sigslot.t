package MyApp;

use Test::More tests => 5;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Application);
use QtCore4::slots
        foo => [],
        slotToSignal => ['int','int'],
        slot => ['int','int'];
use QtCore4::signals
        signal => ['int','int'],
        signalFromSlot => ['int','int'],
        signalWithBadArg => ['int'];

sub NEW {
    shift->SUPER::NEW(@_);

    # 1) testing correct subclassing of Qt::Application and this pointer
    is( ref(this), ' MyApp', 'Correct subclassing' );

    this->connect(this, SIGNAL 'signal(int,int)', SLOT 'slotToSignal(int,int)');
    this->connect(this, SIGNAL 'signalFromSlot(int,int)', SLOT 'slot(int,int)');

    # 4) automatic quitting will test Qt4 sig to custom slot 
    this->connect(this, SIGNAL 'aboutToQuit()', SLOT 'foo()');

    # 2) Emit a signal to a slot that will emit another signal
    emit signal( 5, 4 );

    # 3) Emit a signal, but missing an argument.  Should fail.
    $DB::single=1;
    eval{ emit signalWithBadArg() };
    like( $@, qr/Wrong number of arguments in signal call/, 'Missing arguments in signal' );
}

sub foo {
    pass( 'Qt4 signal to custom slot' );
}     

sub slotToSignal {
    is_deeply( \@_, [ 5, 4 ], 'Custom signal to custom slot' );
    # 3) Emit a signal to a slot from within a signal
    emit signalFromSlot( @_ );
}

sub slot {
    is_deeply( \@_, [ 5, 4 ], 'Signal to slot to signal to slot' );
}

1;

package main;

use QtCore4;
use QtGui4;
use MyApp;

$a = MyApp(\@ARGV);

Qt::Timer::singleShot( 300, $a, SLOT "quit()" );

exit $a->exec;
