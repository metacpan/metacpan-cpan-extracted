BEGIN { print "1..3\n" }

package MyApp;
use Qt;
use Qt::isa qw(Qt::Application);
use Qt::slots
        foo => ['int'],
        baz => [];
use Qt::signals
        bar => ['int'];

sub NEW {
     shift->SUPER::NEW(@_);

     # 1) testing correct subclassing of Qt::Application and this pointer
     print +(ref(this) eq " MyApp")? "ok 1\n" : "not ok\n";
     
     this->connect(this, SIGNAL 'bar(int)', SLOT 'foo(int)');

     # 3) automatic quitting will test Qt sig to custom slot 
     this->connect(this, SIGNAL 'aboutToQuit()', SLOT 'baz()');

     # 2) testing custom sig to custom slot 
     emit bar(3);
}

sub foo
{
    print +($_[0] == 3) ? "ok 2\n" : "not ok\n";
}

sub baz
{
    print "ok 3\n";
}     

1;

package main;

use Qt;
use MyApp;

$a = 0;
$a = MyApp(\@ARGV);

Qt::Timer::singleShot( 300, Qt::app(), SLOT "quit()" );

exit Qt::app()->exec;
