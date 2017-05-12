#!/usr/bin/perl

use strict;
use warnings;
use Wurfl;
use JSON;
use IO::Socket::INET;
use IO::Multiplex;
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

# creating a listening socket
my $socket = new IO::Socket::INET (
    LocalHost => $listen_addr,
    LocalPort => $listen_port,
    Proto => 'tcp',
    Listen => 9999,
    Reuse => 1
);
die "cannot create socket $!\n" unless $socket;
print "server waiting for client connection on address $listen_addr and port $listen_port\n";

my $wurfl = Wurfl->new($wurfl_file);

main();

##############

sub main {
    my $iomux = IO::Multiplex->new();
    $iomux->listen($socket);
    $iomux->set_callback_object(__PACKAGE__);
    $iomux->loop;

    $socket->close();
    exit(0);
}

sub mux_connection {
    my $package = shift;
    my $mux     = shift;
    my $fh      = shift;

    $mux->add($fh);
}

sub mux_eof {
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;

    if ($data{$fh}) {
        send $fh, $data{$fh}, 0;
        delete $data{$fh};
    }
    $mux->shutdown($fh, 1);
}

sub mux_input {
    my $package = shift;
    my $mux     = shift;
    my $fh      = shift;
    my $input   = shift;


    $data{$fh} .= $$input;
    $$input = '';
    if ($data{$fh} =~ /\n$/) {
        my $device = $wurfl->lookup_useragent($data{$fh});
        if ($device) {
            my $resp = {
                device => $device->id,
                match => $device->matcher_name,
                capabilities => $device->capabilities
            };
            $mux->write($fh, to_json($resp)."\n");
        }
        delete $data{$fh};
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
