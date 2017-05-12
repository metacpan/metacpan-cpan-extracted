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

package PMInfoExtr::Analysis;

use strict;
use warnings;

use Moose;
use MetaCPAN::API;

use Data::Dumper;

our $VERSION = 0.002;

has 'mcpan' => (is => 'rw', isa => 'MetaCPAN::API');

has 'unknown_distributions' => (is => 'rw', isa => 'HashRef[Ref]', default => sub { {} });

sub BUILD {
	my $self = shift;
	$self->mcpan(MetaCPAN::API->new());
	return;
}

sub init {
	my $self = shift;
	my $array_ref = shift;
	my $modules_ref = shift;

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Starting Analysis:\n";
	}

	$self->get_cpan_distributions($array_ref, $modules_ref);

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "End of Analysis:\n";
	}
	return;
}

sub get_cpan_distributions {
	my $self = shift;
	my $files_array_ref = shift;
	my $modules_ref = shift;

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "\tHow many modules ? " . scalar @{$files_array_ref} . "\n";
	}

	NEXT: for my $mname (@{$files_array_ref}) {
		my $module_name = $mname->{module};
		next NEXT if ($modules_ref->{$module_name});
		next NEXT if ($self->unknown_distributions->{$module_name});

		my $module = eval { return $self->mcpan->module( $module_name ); };
		if ($@) {
			open my $depends_not_found, ">>", "not_found.log" || die("Not possible to open not_found.log file. $!\n");
			print $depends_not_found "Distribution for $module_name could not be found\n";
			close $depends_not_found;
			$self->unknown_distributions->{$module_name} = {
				name => $module_name,
				file => $mname->{file},
			};
		} else {
			if (not defined ($PMInfoExtr::Distributions::distributions->{$module->{distribution}}) ) {
				$self->find_distribution($module, $modules_ref);
			}
		}
	}
	return;
}

sub find_distribution {
	my $self = shift;
	my $module = shift;
	my $modules_ref = shift;

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "\tChecking $module->{distribution}" . "\n";
	}

	my $distribution = eval { $self->mcpan->release( distribution => $module->{distribution}); };
	if ($@) {
		open my $depends_not_found, ">>", "not_found.log" || die("Not possible to open not_found.log file. $!\n");
		print $depends_not_found "Distribution information could not be found for $module->{distribution}\n";
		close $depends_not_found;
		return;
	} else {
		if (not defined $PMInfoExtr::Distributions::distributions->{$module->{distribution}}) {
			my $dist = {
				name => $distribution->{distribution},
				requirements => $self->get_distribution_dependencies($distribution, $modules_ref),
				version => $distribution->{version},
				provides => $distribution->{provides} ? $distribution->{provides} : [], #ToDo in other way if provides is empty it should be filled with $module ...
			};

			if (defined $distribution->{provides}) {
				#for my $provided_key (keys %{$distribution->{provides}}){
				for my $provided_key (@{$distribution->{provides}}){
					$modules_ref->{$provided_key} = {
						name => $distribution->{distribution},
						version => $distribution->{version},
					};
				}
			}

			$PMInfoExtr::Distributions::distributions->{$module->{distribution}} = $dist;
			#print Dumper $distribution;
		}
	}
	return;
}

sub get_distribution_dependencies {
	my $self = shift;
	my $distribution = shift;
	my $modules_ref = shift;
	#my $dependencies = {};
	my @dependencies = ();

	DEPS: for(@{$distribution->{dependency}}) {
		next DEPS if ($_->{relationship} !~ m/requires/g);
		next DEPS if ($_->{phase} !~ m/runtime/g);

		my $depend = {
			#module => $_,
		};

		my $debian_module = $modules_ref->{$_->{module}};
		if (defined $debian_module) {
			$depend->{name} = $debian_module->{name};
			$depend->{version} = $debian_module->{version};
		} else {
			my $depdist = eval { return $self->mcpan->module($_->{module}); };
			if ($@) {
				#push (@{$dependencies->{unknown}}, $_->{module});
			} else {
				if ($PMInfoExtr::Distributions::distributions->{$depdist->{distribution}}) {
					$depend->{name} = $PMInfoExtr::Distributions::distributions->{$depdist->{distribution}}->{name};
					$depend->{version} = $PMInfoExtr::Distributions::distributions->{$depdist->{distribution}}->{version};
				} else {
					$depend->{name} = $depdist->{distribution};
					$depend->{version} = $depdist->{version};
				}
			}
		}
		push(@dependencies, $depend);
	}
	return \@dependencies;
}

1;
