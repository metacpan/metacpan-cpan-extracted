package Net::FSP::Util;
use strict;
use warnings;
use Exporter qw/import/;
our $VERSION   = $NET::FSP::VERSION;
our @EXPORT_OK = qw/get_envs get_host get_local_dir/;

my %key_for = (
	FSP_PORT      => 'remote_port',
	FSP_LOCALIP   => 'local_address',
	FSP_LOCALPORT => 'local_port',
	FSP_PASSWORD  => 'password',
	FSP_BUF_SIZE  => 'max_payload_size',
	FSP_DIR       => 'current_dir',
	FSP_DELAY     => 'min_delay',
	FSP_MAXDELAY  => 'max_delay',
	FSP_DIR       => 'current_dir',

	# My own invention
	FSP_DELAYFACT => 'delay_factor',
);

sub get_envs {
	my %ret;
	for my $env_key (keys %key_for) {
		$ret{ $key_for{$env_key} } = $ENV{$env_key} if defined $ENV{$env_key};
	}
	return %ret;
}

sub get_host {
	return $ENV{FSP_HOST};
}

sub get_local_dir {
	my $ret = defined $ENV{FSP_LOCAL_DIR} ? $ENV{FSP_LOCAL_DIR} : './';
	$ret =~ s{ (?<= [^/] ) \z }{/}mx;
	return $ret;
}

1;

__END__

=head1 NAME

Net::FSP::Util - Utility functions for Net::FSP

=head1 VERSION

This documentation refers to Net::FSP version 0.13

=head1 DESCRIPTION

By default Net::FSP ignores the environment. To improve compatibility with
other FSP implementations these utility functions are provided.

=head1 SUBROUTINES

=over 4

=item get_envs()

Get options for Net::FSP::new from environmental variables.

=item get_host()

Get the remote host from the appropriate environmental variable.

=item get_local_dir()

Get the local directory from the appropriate environmental variable, or else
it returns "./";

=back

=head1 CONFIGURATION AND ENVIRONMENT

The following environmental variables are used for access FSP servers:

=over 4

=item FSP_HOST

The name or IP address of the machine with the FSP server.

=item FSP_PORT

The port number of the UDP socket used by the FSP server.

=item FSP_LOCALIP

Local Address of UDP socket. This IP address must be one of your local IP
addresses. This variable is mainly used for multihomed hosts.

=item FSP_LOCALPORT

The port number of the UDP socket. You may pick any number not currently used
for other purposes.

=item FSP_PASSWORD

Access password for FSP server. Directories on FSP server can be password
protected. FSP server can change your access level if you have provided a
correct password. There are 2 access levels: public and owner.

=item FSP_BUF_SIZE

Preferred size of server reply. Default is 1024 which is supported by all
servers. Some servers can accept larger packets and you will get some extra
speed with them. You can lower that value if you want to get smaller packets
from server.

=item FSP_DIR

The current working directory of the client in the FSP server.

=item FSP_DELAY

Minimum wait time before resending packet in milliseconds. This should be set close to expected round trip time.

=item FSP_MAXDELAY

Maximum wait time before resending packet in milliseconds.

=item FSP_LOCAL_DIR

Where to look for local files.

=back

=head1 AUTHOR

Leon Timmermans, fawaka@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, 2008 Leon Timmermans. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.
