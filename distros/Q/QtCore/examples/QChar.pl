#!/usr/bin/perl -w

# use blib;
use Qt::QChar;


my $y = QLatin1Char("baaaa"); # QLatin1Char see only first character
print "y(a) = $y\n";
print "y unicode = ", $y->unicode(), "\n";


my $x = QChar($y);
print "x = $x\n";

print "x toLatin1 = ", $x->toLatin1(), "\n";

print "\nok\n";


