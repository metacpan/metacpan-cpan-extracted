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

package NetInfoExtractor::Route;


use warnings;
use strict;

our $VERSION = '0.1';

use Moose;
use Data::Dumper;

has 'routes' => (is => 'rw', isa => 'ArrayRef[Ref]', default => sub { [] });

sub init {
	my $self = shift;
	$self->read_routes();
	return;
}

sub change_byte_order {
	my $network_order = shift;
	my $byte1 = hex($network_order) & 0x000000ff;
	my $byte2 = (hex($network_order) & 0x0000ff00) >> 8;
	my $byte3 = (hex($network_order) & 0x00ff0000) >> 16;
	my $byte4 = (hex($network_order) & 0xff000000) >> 24;

	return "$byte1".".$byte2".".$byte3".".$byte4";
}

sub read_routes {
	my $self = shift;
	open my $route, "<", "/proc/net/route" || die("Could not open file /proc/net/route. $!.");
	my $first_line = <$route>;
	while (<$route>) {
		my ($iface, $destination, $gateway, $flags, $refcnt, $use, $metric, $mask, $mtu, $window, $irtt) = split(' ', $_);

		my $route_info = {
			interface => $iface,
			destination => change_byte_order($destination),
			gateway => change_byte_order($gateway),
			flags => $flags,
			refcnt => $refcnt,
			use => $use,
			metric => $metric,
			mask => change_byte_order($mask),
			mtu => $mtu,
			window => $window,
			irtt => $irtt,
		};
		push(@{$self->routes}, $route_info);
	}
	close $route;
	return;
}
1;
