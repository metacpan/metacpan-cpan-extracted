#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Makefile::Rule;
use Panotools::Makefile::Utils qw/platform/;
ok (1);

my $rule = new Panotools::Makefile::Rule;

$rule->Targets ('C:\Program Files\foo\bar\My output.txt');
$rule->Prerequisites ('C:\WINDOWS\notepad.exe');
$rule->Command ('echo', 'C:\Documents and Settings\All Users\My input.txt');

platform ('linux');

#C:\\Program\ Files\\foo\\bar\\My\ output.txt : C:\\WINDOWS\\notepad.exe
#        echo C:\\Documents\ and\ Settings\\All\ Users\\My\ input.txt

ok ($rule->Assemble =~ /^C:\\\\Program\\ Files\\\\foo/);
ok ($rule->Assemble =~ /\techo C:\\\\Documents\\ and/);

platform ('MSWin32');

#C:/Program\ Files/foo/bar/My\ output.txt : C:/WINDOWS/notepad.exe
#        echo "C:/Documents and Settings/All Users/My input.txt"

ok ($rule->Assemble =~ m|^C:/Program\\ Files/foo|);
ok ($rule->Assemble =~ m|\techo "C:/Documents and Settings/All Users/My input.txt"|);

$rule = new Panotools::Makefile::Rule;

$rule->Prerequisites ('/etc/resolv.conf', '/home/$(USER)/.hugin');
$rule->Targets ('/tmp/foo bar', '/tmp/bar foo');
$rule->Command ('cp', '/etc/resolv.conf', '/tmp/foo bar');
$rule->Command ('cp', '/home/$(USER)/.hugin', '/tmp/bar foo');

platform ('linux');

#/tmp/foo\ bar /tmp/bar\ foo : /etc/resolv.conf /home/$(USER)/.hugin
#        cp /etc/resolv.conf /tmp/foo\ bar
#        cp /home/$(USER)/.hugin /tmp/bar\ foo

ok ($rule->Assemble =~ m|/tmp/foo\\ bar /tmp/bar\\ foo|);
ok ($rule->Assemble =~ m| /home/\$\(USER\)/.hugin|);
ok ($rule->Assemble =~ m|cp /etc/resolv.conf /tmp/foo\\ bar|);
ok ($rule->Assemble =~ m|cp /home/\$\(USER\)/.hugin /tmp/bar\\ foo|);

