#!/usr/bin/perl -w

# use blib;
use Qt;
use Qt::QTimer;
use Qt::QCoreApplication;


my $app = QCoreApplication(\@ARGV);
my $timer = QTimer();
print "app = $app, timer = $timer\n";
$app->connect($timer, SIGNAL('timeout()'), $app, SLOT('quit()'));
$timer->start(2000);

print "start (wait 2 seconds) ...\n";
$app->exec();
print "quit -- OK\n";

print "\nok\n";
