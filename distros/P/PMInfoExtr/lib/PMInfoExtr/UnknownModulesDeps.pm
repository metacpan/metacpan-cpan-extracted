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

package PMInfoExtr::UnknownModulesDeps;

use warnings;
use strict;

use PMInfoExtr::Manager;

=head1 NAME

PMInfoExtr::UnknownModulesDeps; - Fallback when unable to detect installation mode (DPKG, CPAN)

=head1 SYNOPSYS

This package receives every Module that was not detected through DPKG or CPAN to detect their
dependencies. All dependencies are detected at compilation time and parsed in the process_output
function.

=cut

sub new {
	my $class = shift;
	my $self = {
		custom => [],
	};
	return bless $self, $class;
}

sub init {
	my $self = shift;
	my $unknown_hash_ref = shift;
	my $command = "perl -d:Modlist=stop,zerodefault,stdout,nocore";

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Unknown Modules starting\n";
	}

	for my $module (keys %$unknown_hash_ref) {
		my $filename = $unknown_hash_ref->{$module}->{file};
		if ($PMInfoExtr::Manager::options{'debug'}) {
			print STDERR "\tChecking $module\n";
		}

		my $output = `$command $filename 2> /dev/null`;
		my $required_modules = $self->parse_modlist_output ($output);

		push (@{$self->{custom}}, { module => $module, filename => $filename, requires => $required_modules});
	}

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Unknown Modules ending\n";
	}

	return;
}

=head1 Parse Modlist Output function

=cut

sub parse_modlist_output {
	my $self = shift;
	my $text_ref = shift;
	my @required_modules;

	my @several_lines = split ('\n', $text_ref);

	for my $line (@several_lines) {
		#line with Module  Version
		my ($module, $version) = $line =~ m/^(\S*)\s*(\S*)$/s;
		push (@required_modules, { module => $module, version => $version });
	}

	return \@required_modules;
}

1;
