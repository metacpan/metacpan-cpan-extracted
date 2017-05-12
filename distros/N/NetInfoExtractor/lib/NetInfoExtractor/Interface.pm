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

package NetInfoExtractor::Interface;


use warnings;
use strict;

our $VERSION = '0.1';

use Moose;
use Data::Dumper;

my $base_folder = "/sys/class/net";
my @networks;

has 'networks' => (is => 'rw', isa => 'ArrayRef[Ref]');

sub BUILD {
	my $self = shift;
	$self->networks([]);
	return;
}

sub init {
	my $self = shift;
	opendir (DIR, $base_folder) or die "Folder $base_folder was not possible to read: $!\n";
	while (my $networks_folder = readdir (DIR)) {
		next if ($networks_folder =~ m/^\.$/);
		next if ($networks_folder =~ m/^\.\.$/);
		$self->parse_network_interface_folder ($networks_folder);
	}
	closedir(DIR);
	return;
}

sub parse_network_interface_folder {
	my $self = shift;
	my $interface_name = shift;

	my %network_interface = ( name => $interface_name );

	my $folder = $base_folder . "/" . $interface_name;
	opendir (INTF_DIR, $folder) or die "Folder $folder was not possible to read: $!\n";
	while (my $files = readdir(INTF_DIR)) {
		next if ($files =~ m/^\./);

		if ($files eq "address") {
			my $fn = $folder . "/" . $files;
			$network_interface{'macaddress'}  = eval { read_mac_address_file ($fn); };
		}

		if ($files eq "mtu") {
			my $fn = $folder . "/" . $files;
			$network_interface{'mtu'}  = eval { read_mtu_file ($fn); };
		}
		if ($files eq "speed") {
			my $fn = $folder . "/" . $files;
			$network_interface{'speed'}  = eval { read_speed_file ($fn); };
		}
	}
	closedir(INTF_DIR);

	my $ifconfig_output = eval { my $cmd_out = `ifconfig $interface_name`; return $cmd_out; };
	$network_interface{'ipv4'} = parse_ipv4_address($ifconfig_output);
	$network_interface{'ipv6'} = parse_ipv6_address($ifconfig_output);

	push(@{$self->networks}, \%network_interface);
	return;
}

sub parse_ipv4_address {
	my $ifconfig_output = shift;
	my ($ipv4) = $ifconfig_output =~ m/inet\saddr:((\d{1,3}\.){3}\d{1,3})/g;
	return $ipv4;
}

sub parse_ipv6_address {
	my $ifconfig_output = shift;
	my ($ipv6) = $ifconfig_output =~ m/inet6\saddr:\s(.*)\//g;
	return $ipv6;
}

sub read_mac_address_file {
	my $file = shift;
	open my $opened_file, "<", $file || die("Could not open file $file. $!.");
	my $line;
	while (<$opened_file>) {
		chomp $_;
		$line = $_;
	}
	close $opened_file;
	return $line;
}

sub read_mtu_file {
	my $file = shift;
	open my $opened_file, "<", $file || die("Could not open file $file. $!.");
	my $line;
	while (<$opened_file>) {
		chomp $_;
		$line = $_;
	}
	close $opened_file;
	return $line;
}

sub read_speed_file {
	my $file = shift;
	open my $opened_file, "<", $file || die("Could not open file $file. $!.");
	my $line;
	while (<$opened_file>) {
		chomp $_;
		$line = $_;
	}
	close $opened_file;
	return $line;
}
1;
