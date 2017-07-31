#! /usr/bin/perl

use strict;
use Getopt::Long;

die "Example: pask.pl prog_name" unless $ARGV[0];

my $prog_name = $ARGV[0];

mkdir $prog_name or die "Can't not create $prog_name dir";
mkdir $prog_name . "/tasks" or die "Can't not create $prog_name/tasks dir";
mkdir $prog_name . "/storage" or die "Can't not create $prog_name/storage dir";
open my $env_handle, "> $prog_name/.env" or die "Can't not create $prog_name/.env file";
open my $pask_handle, "> $prog_name/pask" or die "Can't not create $prog_name/pask file";
say $env_handle "";
close $env_handle;
say $pask_handle "#! /usr/bin/env perl";
say $pask_handle "use 5.010;\nuse Cwd;\nuse File::Basename;\n";
say $pask_handle "use Pask;\n";
say $pask_handle "Pask::init {\n    base_path => File::Basename::dirname(Cwd::abs_path(__FILE__))\n};\n";
say $pask_handle "Pask::fire(\@ARGV);";
close $pask_handle;
