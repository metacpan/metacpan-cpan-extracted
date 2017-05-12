BEGIN { print "1..6\n" }

package MyApp;
use Qt;
use Qt::isa('Qt::Application');
use Qt::slots
        foo => ['int'],
        baz => [];
use Qt::signals
        bar => ['int'];

sub NEW
{
     shift->SUPER::NEW(@_);
     this->connect(this, SIGNAL 'bar(int)', SLOT 'foo(int)');
     this->connect(this, SIGNAL 'aboutToQuit()', SLOT 'baz()');
}

sub foo
{
    # 1) testing correct inheritance of sig/slots
    print +($_[0] == 3) ? "ok 1\n" : "not ok\n";
}

sub baz
{
    print "ok 3\n";
}     

sub coincoin
{
    print +(@_ == 2) ? "ok 5\n":"not ok\n";
    print +(ref(this) eq " MySubApp") ? "ok 6\n":"not ok\n";
}

1;

package MySubApp;
use Qt;
use Qt::isa('MyApp');


sub NEW 
{
    shift->SUPER::NEW(@_);
    emit foo(3);
}

sub baz
{
   # 2) testing further inheritance of sig/slots
   print "ok 2\n";
   # 3) testing Perl to Perl SUPER
   SUPER->baz();
   # 4) 5) 6) testing non-qualified enum calls vs. Perl method/static calls
   eval { &blue }; print !$@ ? "ok 4\n":"not ok\n";
   coincoin("a","b");
}

1;

package main;

use Qt;
use MySubApp;

$a = 0;
$a = MySubApp(\@ARGV);

Qt::Timer::singleShot( 300, Qt::app(), SLOT "quit()" );

exit Qt::app()->exec;
