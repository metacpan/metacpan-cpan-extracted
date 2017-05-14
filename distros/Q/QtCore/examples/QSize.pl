#!/usr/bin/perl -w

# use blib;
use Qt::QSize;
use Qt;

my $x = QSize();
print "x = $x, \n";
printf "x->ptr = 0x%x\n", $x->{_ptr};
print "x empty = ", $x->isEmpty(), "\n";

$x->setWidth(2);
$x->setHeight(3);
print "x width = ", $x->width(), "\n";

$x->transpose();
print "transpose x: width = ", $x->width(), "\n";

my $y = QSize(4, 5);
print "y = $y\n";
print "y height = ", $y->height(), "\n";

print "y empty = ", $y->isEmpty(), "\n";


$y->scale(10, 10, Qt::IgnoreAspectRatio);
print "scale y: height = ", $y->height(), " wedth = ", $y->width(), "\n";

$x += $y;
print "(x+=y) = $x\n";
print "(x+=y): height = ", $x->height(), " wedth = ", $x->width(), "\n";


print "\nok\n";
