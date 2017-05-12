#!/usr/bin/perl -w
use strict;
use Qt;
use ButtonsGroups;

my $a = Qt::Application(\@ARGV);

my $buttonsgroups = ButtonsGroups;
$buttonsgroups->resize(500, 250);
$buttonsgroups->setCaption("PerlQt Example - Buttongroups");
$a->setMainWidget($buttonsgroups);
$buttonsgroups->show;
exit $a->exec;
