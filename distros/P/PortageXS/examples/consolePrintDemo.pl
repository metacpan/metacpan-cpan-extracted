#!/usr/bin/perl

use warnings;
use strict;

use PortageXS::Colors;

my $pxs = PortageXS::Colors->new();
$pxs->print_ok("This is ok.\n");
$pxs->print_info("This is a warning.\n");
$pxs->print_err("This is an error.\n");
$pxs->setPrintColor('RED'); print "This is red. ";
$pxs->setPrintColor('BLUE'); print "This is blue. ";
$pxs->setPrintColor('YELLOW'); print "This is yellow. ";
$pxs->setPrintColor('RESET'); print "This is normal.\n";

print "\ncalling disableColors();\n";
$pxs->disableColors();

$pxs->print_ok("This is ok.\n");
$pxs->print_info("This is a warning.\n");
$pxs->print_err("This is an error.\n");
$pxs->setPrintColor('RED'); print "This is red. ";
$pxs->setPrintColor('BLUE'); print "This is blue. ";
$pxs->setPrintColor('YELLOW'); print "This is yellow. ";
$pxs->setPrintColor('RESET'); print "This is normal.\n";

print "\ncalling restoreColors();\n";
$pxs->restoreColors();

$pxs->print_ok("This is ok.\n");
$pxs->print_info("This is a warning.\n");
$pxs->print_err("This is an error.\n");
$pxs->setPrintColor('RED'); print "This is red. ";
$pxs->setPrintColor('BLUE'); print "This is blue. ";
$pxs->setPrintColor('YELLOW'); print "This is yellow. ";
$pxs->setPrintColor('RESET'); print "This is normal.\n";

