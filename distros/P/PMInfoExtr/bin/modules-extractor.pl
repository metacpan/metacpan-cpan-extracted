#!/usr/bin/perl

#
# Copyright (c) 2014, Caixa Magica Software Lda (CMS).
# The work has been developed in the TIMBUS Project and the above-mentioned are Members of the TIMBUS Consortium.
# TIMBUS is supported by the European Union under the 7th Framework Programme for research and technological
# development and demonstration activities (FP7/2007-2013) under grant agreement no. 269940.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at:   http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including without
# limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTIBITLY, or FITNESS FOR A PARTICULAR
# PURPOSE. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise,
# unless required by applicable law or agreed to in writing, shall any Contributor be liable for damages, including
# any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this
# License or out of the use or inability to use the Work.
# See the License for the specific language governing permissions and limitation under the License.
#

#Author(s):
#	Nuno Martins <nuno.martins@caixamagica.pt>

use strict;
use warnings;
use v5.14;

use PMInfoExtr::Manager;
use Cwd;
use Getopt::Long;

our $VERSION = 0.002;

my $manager = PMInfoExtr::Manager->new();

sub add_folders {
	my ($opt_name, $opt_value) = @_;
	$manager->push_folders($opt_value);
}

sub output_file {
	my ($opt_name, $opt_value) = @_;
	$manager->set_options('output_file', $opt_value);
	return $opt_value;
}

sub help {
	my $line = shift;
	my $help_line = "perl $0 [--config-path-file = config_path_file | --debug | --folders = folder_name | --help | --include | --output = output_file]";
	if ($line) {
		print <<EOF;
$line

$help_line
EOF
	} else {
		print <<EOF;
$help_line
EOF
	}

	return;
}

sub read_config_path_file {
	my ($opt_name, $opt_value) = @_;
	if (-e $opt_value) {
		open my $path_config, "<", $opt_value or die("Could not open file $opt_value\n$!.");
		while (<$path_config>) {
			chomp $_;
			$manager->push_folders($_);
		}
		close $path_config;
	} else {
		help("Config file $opt_value does not exit");
		exit -1;
	}
}

sub main {
	my @options = @_;
	my $help = 0;
	my $debug = 0;
	my $include = 0;

	GetOptions (
		'help!' => \$help,
		'debug!' => \$debug,
		'folders=s' => \&add_folders,
		'output=s' => \&output_file,
		'include!' => \$include,
		'config-path-file=s' => \&read_config_path_file,
	);

	if ($help) {
		help();
		exit 0;
	}

	$manager->set_options("debug", $debug);

	if ($include) {
		for (@INC) {
			my $link = readlink ($_);
			if (defined $link) {
				my ($path) = $_ =~ m/(.*\/)/g;
				$manager->push_folders($path . $link);
				$manager->push_folders($_);
			} else {
				if ($_ =~ m/^\.$/g) {
					$manager->push_folders(cwd());
				} else {
					$manager->push_folders($_);
				}
			}
		}
	}

	unlink "not_found.log";
	$manager->start();
	return;
}

main(@ARGV);