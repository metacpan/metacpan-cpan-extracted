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

package PMInfoExtr::Report;

use strict;
use warnings;

use Moose;
use JSON;
use UUID::Tiny ':std';

our $VERSION = 0.002;

sub init {
	my $self = shift;
	my $data = shift;

	if ($PMInfoExtr::Manager::options{'debug'}) {
		print STDERR "Reporting:\n";
		print STDERR "\tDistributions: " . scalar (keys %{$data->{distributions}} ) ."\n";
		print STDERR "\tUnknown Modules: " . scalar (@{$data->{custom}}) ."\n";
	}

	$self->print_array_to_json($data);
	return;
}

sub print_array_to_json {
	my $self = shift;
	my $data = shift;
	my $json = JSON->new->utf8;

	$json->convert_blessed(1);
	$json->allow_blessed(1);

	my %perl = (
		result => {
			data => $data,
			nodeUUID => "",
		},
		UUID => uuid_to_string(create_uuid()),
		format => {
			id => "d7f5e025-9daa-11e3-ab53-e3e54faab75e",
			multiple => JSON::false,
		},
	);

	if (defined $PMInfoExtr::Manager::options{'output_file'}) {
		unlink $PMInfoExtr::Manager::options{'output_file'} if ( -e $PMInfoExtr::Manager::options{'output_file'} );
		open my $report, ">", $PMInfoExtr::Manager::options{'output_file'} or die("ERROR opening file ". $PMInfoExtr::Manager::options{'output_file'} . " . $!\n");
		print $report $json->encode(\%perl);
		close $report;
	} else {
		print STDOUT $json->encode(\%perl);
	}

	return;
}
1;