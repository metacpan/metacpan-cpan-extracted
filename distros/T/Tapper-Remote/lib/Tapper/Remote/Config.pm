package Tapper::Remote::Config;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Remote::Config::VERSION = '5.0.0';
use strict;
use warnings;

use Getopt::Long;
use Moose;
use Net::TFTP;
use Socket;   # for inet_aton and gethostbyname
use Sys::Hostname;
use YAML::Syck;





sub get_tapper_host
{
        my ($host, $port);
        # try kernel command line
        open my $FH,'<','/proc/cmdline';
        my $cmd_line = <$FH>;
        close $FH;
        ($host,undef,$port) = $cmd_line =~ m/tapper_host\s*=\s*(\w+)(:(\d+))?/;
        return($host,$port) if $host;

        if (my ($ip) = $cmd_line =~ m/tapper_ip\s*=\s*(\S+)/) {
                my $iaddr = inet_aton($ip);
                $host  = gethostbyaddr($iaddr, AF_INET);

                ($port) = $cmd_line =~ m/tapper_port\s*=\s*(\d+)/;
                  return($host,$port) if $host;
        }


        # try %ENV
        if ($ENV{TAPPER_MCP_SERVER}) {
                $host = $ENV{TAPPER_MCP_SERVER};
                $port = $ENV{TAPPER_MCP_PORT};
                return ($host, $port);
        }

        # try multicast
}



sub gethostname
{
        my ($self) = @_;
        my $hostname = Sys::Hostname::hostname();
        if ($hostname   =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($hostname) = gethostbyaddr(inet_aton($hostname), AF_INET) or ( print("Can't get hostname: $!") and exit 1);
                $hostname   =~ s/^(\w+?)\..+$/$1/;
                system("hostname", "$hostname");
        } elsif ($hostname  =~ m/^([^\.]+)\./) {
                $hostname   = $1;
        }
        return $hostname;
}




sub get_local_data
{
        my ($self, $state) = @_;
        # logger will usually be initialised by caller
        my $tmpcfg={};

        my $config_file_name = '/etc/tapper';
        $config_file_name = $ENV{TAPPER_CONFIG} if $ENV{TAPPER_CONFIG};

        my $hostname = $self->gethostname();


        my ($server, $port, $help);
        Getopt::Long::GetOptions("host=s"   => \$server,
                                 "port=s"   => \$port,
                                 "config=s" => \$config_file_name,
                                 "help|h"   => \$help,);
        die "Usage: $0 [--host=host --port=port --config=file]\n" if $help;

        if ($state eq 'install' or (not -e $config_file_name)) {
                ($server, $port)    = $self->get_tapper_host() if not $server;
                my $tftp            = Net::TFTP->new($server);
                $tftp->get("$hostname-$state", $config_file_name) or return("Can't get local data.",$tftp->error);
                $tmpcfg->{server}   = $server;
                $tmpcfg->{port}     = $port;
                $tmpcfg->{hostname} = $hostname;
        }

        my $config = YAML::Syck::LoadFile($config_file_name) or return ("Can't parse config received from server");
        $config->{filename} = $config_file_name;
        $config->{hostname} = $hostname unless $config->{hostname};
        %$config=(%$config, %$tmpcfg);

        return $config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Remote::Config

=head1 SYNOPSIS

 use Tapper::Remote::Config;

=head1 NAME

Tapper::Remote::Config - Get configuration from Tapper host

=head1 FUNCTIONS

=head2 get_tapper_host

Get hostname of tapper MCP host from kernel boot parameters.

@returnlist ($host,port) - string, int - hostname and port of MCP server

=head2 gethostname

This function returns the host name of the machine. When NFS root is
used together with DHCP the hostname set in the kernel usually equals
the IP address received from DHCP as a string. In this case the kernel
hostname is set to the DNS hostname associated to this IP address.

@return hostname of the machine as set in the kernel

=head2 get_local_data

Get local data needed for all tools running locally on NFS. The function tries
to get the MCP host and fetches the config from there. This reduces any need
for configuration outside MCP host and thus allows to use unchanged NFS root
file systems for both testing and production, with different MCP servers and
so on.

@param string - state

@return success - hash reference containing the config
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
