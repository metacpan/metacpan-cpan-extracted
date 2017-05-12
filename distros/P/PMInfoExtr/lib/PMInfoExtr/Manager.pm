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

package PMInfoExtr::Manager;

use strict;
use warnings;

use Moose;
use PMInfoExtr::Search;
use PMInfoExtr::DpkgInformation;
use PMInfoExtr::Acquisition;
use PMInfoExtr::Analysis;
use PMInfoExtr::Report;

use PMInfoExtr::Distributions;
use PMInfoExtr::UnknownModulesDeps;

our $pm = {};

our $VERSION = 0.002;
our %options = (
	'debug' => 0,
	'folders' => [],
);

use Data::Dumper;

has 'search' => (is => 'rw', isa => 'PMInfoExtr::Search');

has 'dpkg' => (is => 'rw', isa => 'PMInfoExtr::DpkgInformation');

has 'acquire' => (is => 'rw', isa => 'PMInfoExtr::Acquisition');

has 'report' => (is => 'rw', isa => 'PMInfoExtr::Report');

has 'analysis' => (is => 'rw', isa => 'PMInfoExtr::Analysis');

has 'distributions' => (is => 'rw', isa => 'PMInfoExtr::Distributions');

has 'unknowndeps' => (is => 'rw', isa => 'PMInfoExtr::UnknownModulesDeps');

sub BUILD {
	my $self = shift;

	$self->search(PMInfoExtr::Search->new());
	$self->dpkg(PMInfoExtr::DpkgInformation->new());
	$self->acquire(PMInfoExtr::Acquisition->new());
	$self->analysis(PMInfoExtr::Analysis->new());
	$self->report(PMInfoExtr::Report->new());
	$self->distributions(PMInfoExtr::Distributions->new());
	$self->unknowndeps(PMInfoExtr::UnknownModulesDeps->new());
	return;
}

sub set_options {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	$options{$key} = $value;
	return;
}

sub push_folders {
	my $self = shift;
	my $value = shift;

	push @{$options{'folders'}}, $value;
	return;
}

sub start {
	my $self = shift;
#gather information from finding Perl Modules and from DPKG
	$self->search->init();
	$self->dpkg->init();
#file information gathering is over

#beginning the minus operation between whole files and dpkg files
	my %all_files = map{$_ => 1} @{$self->search->files};
	my %dpkg_files = map{$_ => 1} @{$self->dpkg->only_files};
	my @otherarray = @{$self->dpkg->only_files};
	my @array = grep($all_files{$_}, @otherarray);
	my @excluded_array = grep(!defined $dpkg_files{$_}, @{$self->search->files});
#end of minus operation

	my $raw_modules = $self->acquire->init(\@excluded_array);

	$self->distributions->init($self->dpkg->perl_packages);

	$self->analysis->init($raw_modules, $self->distributions->modules);

	my @sorted_modules = sort keys %{$self->distributions->modules};
	$pm = \@sorted_modules;

	$self->unknowndeps->init($self->analysis->unknown_distributions);

	$self->report->init({
		search_path 	=> $options{'folders'},
		distributions 	=> $PMInfoExtr::Distributions::distributions,
		custom 			=> $self->unknowndeps->{custom},
	});

	return;
}

1;
