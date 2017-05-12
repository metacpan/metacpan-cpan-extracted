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

package PMInfoExtr::DpkgInformation;

use strict;
use warnings;

use Moose;
use DPKG::Parse::Status;

our $VERSION = 0.002;

has 'perl_packages' => (is => 'rw', isa => 'HashRef[Ref]', default => sub { {} });
has 'only_files' => (is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] });
has 'info_folder' => (is => 'ro', isa => 'Str', default => "/var/lib/dpkg/info/");

sub init {
	my $self = shift;

	$self->dpkg_info();
	if ($PMInfoExtr::Manager::options{'debug'}) {
		my $num = keys $self->perl_packages;
		print STDERR "Perl Packages: $num\n";
	}
	return;
}

sub dpkg_info {
	my $self = shift;
	my $status = DPKG::Parse::Status->new;

	$status->parse();

	while (my $entry = $status->next_package) {
		my $files = $self->read_package_files($entry->package);
		if (scalar (@$files) > 0 ) {
			my $nentry = {
				entry => $entry,
				files => $files,
				dependencies => $self->dpkg_package_dependency($entry),
			};
			$self->perl_packages->{$entry->package} = $nentry;
		}
	}
	return;	
}

sub dpkg_package_dependency {
	my $self = shift;
	my $pkg_entry = shift;
	my @splitted = ();
	my $raw_dependency = $pkg_entry->{depends};
	if (defined $raw_dependency) {
		for (split(', ', $raw_dependency)) {
			push(@splitted, $_);
		}
	}
	my $pre_depends = $pkg_entry->{pre_depends};
	if (defined $pre_depends) {
		for (split(', ', $pre_depends)) {
			push(@splitted, $_);
		}
	}
	return \@splitted;
}

sub read_package_files {
	my $self = shift;
	my $package_name = shift;
	my $package_files = [];
	my $package_file_name = $self->info_folder . $package_name .".list";

	if (-e $package_file_name) {
		open my $fd, "<", $package_file_name || die ("Could not open file $package_file_name . $!.");
		N: while (<$fd>) {
			next N if ($_ !~ m/.*\.pm$/g);
			chomp $_;
			push (@{$package_files}, $_);
			push (@{$self->only_files}, $_);
		}
		close $fd;
	}

	return $package_files;
}
1;
