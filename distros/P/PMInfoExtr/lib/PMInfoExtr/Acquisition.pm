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

package PMInfoExtr::Acquisition;

use strict;
use warnings;

use Moose;

our $VERSION = 0.002;

sub init {
	my $self = shift;
	my $modules_ref = shift;
	my $return_modules;

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Starting acquisition phase\n";
		print STDERR "\tnumber of modules " . scalar @{$modules_ref} ."\n";
	}

	$return_modules = $self->fill_modules($modules_ref);
	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Ended acquisition phase\n";
		print STDERR "\tNumber of modules " . scalar @$return_modules . "\n";
	}
	return $return_modules;
}

sub fill_modules {
	my $self = shift;
	my $perl_modules_files_ref = shift;
	my $paths = $PMInfoExtr::Manager::options{'folders'};

	my @modules_array = ();

	OTHER: for my $f (@$perl_modules_files_ref) {
		NEXT: for my $p (@{$paths}) {
			next NEXT if ($f !~ m/$p\/.*\.pm/g);

			my $module = $f;
			$module =~ s/$p\///g;
			$module =~ s/\//::/g;
			next OTHER if ($module =~ m/^::/g);
			$module =~ s/\.pm//g;
			push (@modules_array, { module => $module, file => $f });
			next OTHER;
		}
	}
	return \@modules_array;
}
1;