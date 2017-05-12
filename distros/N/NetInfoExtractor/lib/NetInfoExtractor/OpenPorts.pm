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

package NetInfoExtractor::OpenPorts;


use warnings;
use strict;

our $VERSION = '0.1';

use Moose;

has 'openports' => (is => 'rw', isa => 'ArrayRef[Ref]', default => sub { [] });

sub init {
	my $self = shift;
	$self->parse_netstat();
	return;
}

sub parse_netstat {
	my $self = shift;
	my $output = `netstat -ltun`;
	my @lines = split("\n", $output);

	for (@lines) {
		next if (/Active/);
		next if (/Proto/);

		my ($proto, $rcv, $snd, $local, $remote, $status) = split(' ');
		my ($laddress, $lport) = $local =~ m/^(.*):(.*)$/g;
		my ($raddress, $rport) = $remote =~ m/^(.*):(.*)$/g;

		push (@{$self->openports}, {
			local_address => $laddress,
			local_port => $lport,
			protocol => $proto,
			remote_address => $raddress,
			remote_port => $rport

		});
	}
	return;
}

1;