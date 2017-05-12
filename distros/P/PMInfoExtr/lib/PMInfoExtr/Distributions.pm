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

package PMInfoExtr::Distributions;

use strict;
use warnings;

use Moose;
use Data::Dumper;

our $VERSION = 0.002;

our $distributions = {};

has 'modules' => (is => 'rw', isa => 'HashRef[Ref]', default => sub { {} } );

sub init {
	my $self = shift;
	my $dpkg_packages = shift;

	for my $pname (keys %{$dpkg_packages}) {
		my $p = $dpkg_packages->{$pname};
		$p->{modules} = $self->trim_path_from_files($p->{files}, $PMInfoExtr::Manager::options{'folders'});

		my $cpan_name = $self->strip_dpkg_name($pname);
		$distributions->{$cpan_name} = {
			name => $pname,
			version => $p->{entry}->{version},
			requirements => $self->dpkg_package_dependency($p->{entry}),
			provides => $p->{modules},
			'installed-by' => "DPKG",
			files => $p->{files},
		};

		for (@{$p->{modules}}) {
			$self->modules->{$_} = $distributions->{$cpan_name};
		}
	}
	return;
}

sub strip_dpkg_name {
	my $self = shift;
	my $name = shift;
	my ($changed_name) = $name =~ m/^lib(.*)\-perl$/g;
	if (defined $changed_name) {
		return $changed_name;
	}
	return $name;
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

sub trim_path_from_files {
	my $self = shift;
	my $files = shift;
	my $paths = shift;
	my ($sentinel) = @{$files};

	$paths = \@INC if (!scalar (@$paths));

	my @return_files = ();
	OTHER: for my $f (@{$files}) {
		NEXT: for my $p (@{$paths}) {
			next NEXT if ($f !~ m/$p\/.*\.pm/g);

			my $module = $f;
			$module =~ s/$p\///g;
			$module =~ s/\//::/g;
			next OTHER if ($module =~ m/^::/g);
			$module =~ s/\.pm//g;
			push (@return_files, $module);
			next OTHER;
		}
	}
	return \@return_files;
}
1;
