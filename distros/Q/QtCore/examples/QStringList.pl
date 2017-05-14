#!/usr/bin/perl -w

# use blib;
use Qt::QByteArray;
use Qt::QString;
use Qt::QStringList;

my @sl;

$sl[0] = QString("one");
$sl[1] = QString("two");

print "s10=", $sl[0]->toLatin1()->data(), ", sl1=", $sl[1]->toLatin1()->data(), "\n";
my $aa = QStringList(\@sl);
print "aa = $aa\n";
my $bb = $aa->join(QString(' + '));
print "bb = $bb\n";
print "join slx = ", $bb->toLatin1()->data(), "\n";

print "\nok\n";
