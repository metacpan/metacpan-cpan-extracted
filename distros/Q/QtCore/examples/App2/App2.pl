#!/usr/bin/perl -w

# use blib;
use MyApp;

my $a = MyApp::MyApp(\@ARGV);

print "$a : start...\n";
$a->exec();

print "\nok\n";
