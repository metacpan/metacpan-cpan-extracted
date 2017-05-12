#!/usr/bin/perl -w

use strict;
use warnings;

use lib "lib";

use IO::Socket;
use Net::Printer;
use Test::More;

# Define some handy constants
use constant LPD_SERVER  => $ENV{LPD_SERVER}  || "localhost";
use constant LPD_PRINTER => $ENV{LPD_PRINTER} || "lp";
use constant LPD_PORT    => $ENV{LPD_PORT}    || 515;

{

        # First check to see if we can connect to given print server
        my $sock = IO::Socket::INET->new(Proto    => 'tcp',
                                         PeerAddr => LPD_SERVER,
                                         PeerPort => LPD_PORT
        );

        if (!$sock) {
                plan skip_all =>
                    sprintf("Unable to connect to %s port %d.  Aborting",
                            LPD_SERVER, LPD_PORT);
        } else {
                plan tests => 3;
        }

        my $printer = Net::Printer->new(lineconvert => "Yes",
                                        server      => LPD_SERVER,
                                        printer     => LPD_PRINTER,
                                        port        => LPD_PORT,
                                        rfc1179     => "No",
                                        debug       => "No"
        );

        ok(defined($printer));
        ok(defined $printer->printfile("./testprint.txt"));

        my @status = $printer->queuestatus();

        foreach my $line (@status) {
                $line =~ s/\n//;
                print "$line\n";
        }

        ok(scalar @status > 0);

        print "Please check your default printer for printout.\n";

}
