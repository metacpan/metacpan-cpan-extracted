#!/usr/bin/perl -w
use strict;
use blib;
use Qt;

my $a = Qt::Application(\@ARGV);

my $hello = Qt::PushButton("Hello World!", undef);
$hello->resize(100, 30);

$a->setMainWidget($hello);
$hello->show;
exit $a->exec;
