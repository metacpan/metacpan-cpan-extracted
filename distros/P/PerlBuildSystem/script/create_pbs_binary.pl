#!/usr/bin/perl -w

use strict ;
use warnings ;

my $pbs = `which pbs` ;
chomp $pbs ;

my $pbs_lib_path = `pbs --display_pbs_lib_path` ;
my $pbs_plugins_path = `pbs --display_pbs_plugin_path` ;

my @extra_modules = 
	qw(
	PBS::WatchClient PBS::Prf PBS::Warp1_5 PBS::ProgressBar
	Devel::Depend::Cl 
	Devel::Depend::Cpp 
	Pod::Simple::HTMLBatch 
	Devel::Size 
	File::Slurp 
	) ;

my $extra_modules = '-M ' . join(' -M ', @extra_modules) ;

print "Running command: 'pp -P -d -c -o ./tmp/pbs $pbs -a '$pbs_lib_path/;/PBSLIB/' -a '$pbs_plugins_path/;/PBSPLUGIN/' $extra_modules'\n" ;

`pp -P -d -c -o ./tmp/pbs $pbs -a '$pbs_lib_path/;/PBSLIB/' -a '$pbs_plugins_path/;/PBSPLUGIN/' $extra_modules` ;

