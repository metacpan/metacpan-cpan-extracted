#!/usr/bin/perl

use strict;
use warnings;
use Wurfl;
use JSON;
use base qw(Net::Server::HTTP);

use Getopt::Long;

my %data;

$| = 1;

my $foreground = 0;
my $debug = 0;
my $listen_addr = "0.0.0.0";
my $listen_port = "4321";
my $wurfl_file = "/usr/share/wurfl/wurfl.xml";
my $help = 0;
  
my $result = GetOptions("foreground"    => \$foreground,
                        "debug=i"       => \$debug,
                        "listen=s"      => \$listen_addr,
                        "port=i"        => \$listen_port,
                        "wurfl_file=s"  => \$wurfl_file,
                        "help"          => \$help);

usage() if ($help);

my $wurfl = Wurfl->new($wurfl_file);

main->run(host => $listen_addr, port => $listen_port);

##############

sub process_http_request {
    my $self = shift;

    my $info = $self->http_request_info;
    my $path = $info->{request_path};
    if ($path =~ s/^\/lookup\/// && $path) {
        my $device = $wurfl->lookup_useragent($path);
        if ($device) {
            my $resp = {
                device => $device->id,
                match => $device->matcher_name,
                capabilities => $device->capabilities,
                virtual_capabilities => $device->virtual_capabilities
            };
            print "Content-type: application/json\n\n";
            print to_json($resp)."\n";
        }
    } else {
        $self->send_status(400, "NOT SUPPORTED", "400 NOT SUPPORTED");
    }
}

sub usage {
    die sprintf("Usage: %s [OPTION]...\n".
                "Possible options:\n".
                "    -f                    run in foreground\n".
                "    -d <level>            debug level\n".
                "    -l <ip_address>       ip address where to listen for incoming connections\n".
                "    -p <port>             tcp port where to listen for incoming connections\n".
                "    -w <wurfl_file>       path to the wurfl xml file\n", $0);
}
