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

package NetInfoExtractor::Report;

use warnings;
use strict;

our $VERSION = '0.1';

use Moose;
use JSON;
use UUID::Tiny ':std';

has 'json' => (is => 'rw', isa => 'JSON');
has 'json_data' => (is => 'rw', isa => 'HashRef[Ref]');

sub BUILD {
	my $self = shift;

	$self->json(JSON->new->utf8);
	$self->json->convert_blessed(1);
	$self->json->allow_blessed(1);
	$self->json_data({});
	my $v1_mc_UUID = create_uuid();
	$self->json_data->{format} = {
		id => "b744635a-9d6b-11e3-8ec0-da765d6aa4db",
		multiple => JSON::false,
	};
	$self->json_data->{result} = {
		data => {
			network_interfaces => [],
			#firewall => {},
			#bridges => {},
			routes => [],
			nameservers => [],
			openports => [],
		},
		nodeUUID => "",
	};
	$self->json_data->{uuid} = uuid_to_string($v1_mc_UUID);
}

sub init {
	my $self = shift;
	my $networks_ref = shift;
	my $routes = shift;
	my $nameserver = shift;
	my $openports = shift;
	my $outputfile = shift || undef;

	$self->json_data->{result}->{data}->{network_interfaces} = $networks_ref;
	$self->json_data->{result}->{data}->{routes} = $routes;
	$self->json_data->{result}->{data}->{nameservers} = $nameserver;
	$self->json_data->{result}->{data}->{openports} = $openports;

	if (defined $outputfile ) {
		open my $report, ">", $outputfile or die("ERROR opening file ". $outputfile . " . $!\n");
		print $report $self->json->encode($self->json_data);
		close $report;
	} else {
		print STDOUT $self->json->encode($self->json_data);
	}
}
1;
