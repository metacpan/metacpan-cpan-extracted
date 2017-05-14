#!/usr/bin/perl -w

# use blib;
use Qt::QByteArray;
use Qt::QString;

my $x = QLatin1String("xxyyzz");
print "x = $x\n";
print "x latin1 = ", $x->latin1(), "\n";

my $y = QString($x);
print "y = $y\n";

print "x == y\n" if $x == $y;

undef $x;
undef $y;

my $z = QString("qwerty");
print "z = $z:", $z->toLatin1()->data(), " \n";

print "\nok\n";
