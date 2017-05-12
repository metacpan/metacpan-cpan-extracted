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
use Getopt::Long;

use NetInfoExtractor::Interface;
use NetInfoExtractor::Report;
use NetInfoExtractor::Route;
use NetInfoExtractor::NameServer;
use NetInfoExtractor::OpenPorts;

my $options = { };
my $help = 0;

sub out_file {
	my ($opt_name, $opt_value) = @_;
	if (not $opt_value) {
		print STDERR "Missing output filename\n";
		print_help_msg(\*STDERR);
	}
	$options->{output} = $opt_value;
	return $opt_value;
}

sub print_help_msg {
	my $to = shift || \*STDOUT;
	print $to "$0 [--output filename] [--help]\n";
	exit;
}

sub main {
	GetOptions (
		'output=s' => \&out_file,
		'help!' => \$help
	);

	if ($help) {
		print_help_msg();
	}

	my $int = NetInfoExtractor::Interface->new();
	$int->init();
	my $route = NetInfoExtractor::Route->new();
	$route->init();
	my $nm = NetInfoExtractor::NameServer->new();
	$nm->init();
	my $op = NetInfoExtractor::OpenPorts->new();
	$op->init();
	my $report = NetInfoExtractor::Report->new();
	$report->init($int->networks, $route->routes, $nm->nameserver, $op->openports, $options->{output});

	return;
}

main();
