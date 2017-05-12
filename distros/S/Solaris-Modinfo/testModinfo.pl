#!/usr/bin/perl -w

use strict;
use Solaris::Modinfo;

my $module  = Solaris::Modinfo->new();
my $modinfo = $module->listModule();

print "Number of modules : ", $module->countModule(), "\n";

map {
	print $modinfo->{$_}{Id}, "  ",
		$modinfo->{$_}{Loadaddr}, "  ",
		$modinfo->{$_}{Size}, "  ",
		$modinfo->{$_}{Info}, "  ",
		$modinfo->{$_}{Rev}, "  ",
		$modinfo->{$_}{ModuleName}, "\n";
}(keys %{ $modinfo });

