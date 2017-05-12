#!/usr/bin/perl

use strict;
use Net::Server;
use base 'Net::Server::PreFork';
use IPC::Open3;
use IO::Select;

my $port = shift;
my @cmd  = @ARGV;

die "port cmd cmd cmd cmd cmd cmd cmd" unless $port and @cmd;

sub process_request {
    my $this = shift;
    my ($wtr, $rdr, $err);
    my $pid = open3($wtr, $rdr, $err, @cmd);

     $rdr->blocking(0);
    STDIN->blocking(0);

    my $select = IO::Select->new($rdr, \*STDIN);
    TOP: while(1) {
        if( my @handles = $select->can_read(1) ) {
            for(@handles) {
                my $at_least_one = 0;

                while( my $line = $_->getline ) {
                    if( $_ == $rdr ) {
                        print STDOUT $line;
                        $this->log(1, "[IMAP] $line");

                    } else {
                        print $wtr $line;
                        $this->log(1, "[CLNT] $line");
                    }

                    $at_least_one ++;
                }

                last TOP unless $at_least_one;
            }
        }
    }

    $this->log(1, "[KILL] $pid must die");

    kill -1, $pid;
    kill -2, $pid;
    waitpid $pid, 0;

    return;
}

main->run(port=>$port, log_file=>"ppsc.log");
