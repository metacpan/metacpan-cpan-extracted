#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::HomeDir;
use Path::Class;

# --------------

my($app_name)    = 'Module-Metadata-CoreList';
my($config_name) = '.htmodule.metadata.corelist.conf';
my($dir_name)    = File::HomeDir -> my_dist_config($app_name, {create => 1});

if ($dir_name)
{
	my($source_file_name) = Path::Class::file('config', $config_name);

	File::Copy::copy($source_file_name, $dir_name);

	my($dest_file_name) = Path::Class::file($dir_name, $config_name);

	if (-e $dest_file_name)
	{
		print "Copied config/$config_name to $dir_name\n";
	}
	else
	{
		die "Unable to copy $source_file_name to $dir_name\n";
	}
}
else
{
	print "Unable to create directory using File::HomeDir -> my_dist_config('$app_name', {create => 1})\n";
	die "for use by File::Copy::copy(Path::Class::file('config', '$config_name'), \$dir_name)\n";
}
