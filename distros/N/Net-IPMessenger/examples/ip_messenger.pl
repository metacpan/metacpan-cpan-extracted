#!/usr/bin/perl

use strict;
use warnings;
use Encode qw( encode decode from_to );
use Encode::Guess;
use IO::Select;
use IO::Handle;
use IO::Interface::Simple;
use Sys::Hostname;
use Term::Encoding qw(term_encoding);
use Net::IPMessenger::CommandLine;
use Net::IPMessenger::ToStdoutEventHandler;

use constant {
    GROUPNAME => 'ipmsg',
    NICKNAME  => 'ipmsg',
    USERNAME  => 'ipmsg',
    HOSTNAME  => hostname,
    TIMEOUT   => 3,
};

local $SIG{INT} = 'ignore';
STDOUT->autoflush(1);

my $version  = "0.07";
my $encoding = term_encoding;

my $ipmsg = Net::IPMessenger::CommandLine->new(
    NickName  => to_sjis(NICKNAME),
    GroupName => to_sjis(GROUPNAME),
    UserName  => USERNAME,
    HostName  => HOSTNAME,
    Debug     => 1,
) or die "cannot new Net::IPMessenger::CommandLine : $!\n";

my( $serveraddr, $broadcast ) = get_if($ipmsg);
die "get serveraddr failed\n" unless $serveraddr;

$ipmsg->use_secret(1);
$ipmsg->serveraddr($serveraddr);
$ipmsg->add_broadcast($broadcast);
$ipmsg->add_event_handler( new Net::IPMessenger::ToStdoutEventHandler );

my $socket = $ipmsg->get_connection;
my $select = IO::Select->new( $socket, \*STDIN );

local $SIG{ALRM} = sub {
    $ipmsg->flush_sendings;
    alarm( TIMEOUT + 1 );
};
alarm( TIMEOUT + 1 );

prompt();
while (1) {
    my @ready = $select->can_read(TIMEOUT);

    for my $handle (@ready) {
        # stdin
        if ( $handle eq \*STDIN ) {
            my $msg = $handle->getline or next;
            chomp $msg;

            my( $cmd, @options ) = split /\s+/, to_sjis($msg);
            if ( $ipmsg->is_writing ) {
                $ipmsg->writing($cmd);
                next;
            }
            unless ($cmd) {
                $cmd = 'read';
            }
            if ( $ipmsg->can($cmd) ) {
                if ( $cmd eq 'can' or $cmd eq 'isa' or $cmd eq 'VERSION' ) {
                    prompt("command not supported");
                    next;
                }
                $msg = $ipmsg->$cmd(@options);
            }
            else {
                prompt("command unknown");
                next;
            }
            from_to( $msg, 'shiftjis', $encoding );
            if ( defined $msg ) {
                print $msg, "\n";
                exit if $msg eq 'exiting';
            }
            prompt( "", $ipmsg );
        }
        # socket
        elsif ( $handle eq $socket ) {
            $ipmsg->recv;
            alarm( TIMEOUT + 1 );
        }
    }
}

######################################################################
# Sub Routine
######################################################################

sub get_if {
    my $socket = shift->socket;

    my @interfaces = IO::Interface::Simple->interfaces;
    for my $if (@interfaces) {
        if ( not $if->is_loopback and $if->is_running and $if->is_broadcast ) {
            return( $if->address, $if->broadcast );
        }
    }
    return;
}

sub to_sjis {
    my $str = shift;
    my $enc = guess_encoding( $str, qw( euc-jp shiftjis 7bit-jis ) );

    my $name;
    if ( ref($enc) ) {
        $name = $enc->name;
        if ( $name ne 'shiftjis' and $name ne 'ascii' ) {
            from_to( $str, $name, 'shiftjis' );
        }
    }
    else {
        from_to( $str, $encoding, 'shiftjis' );
    }

    return $str;
}

sub prompt {
    my $msg   = shift;
    my $ipmsg = shift;

    return if $ipmsg and $ipmsg->is_writing;
    printf "%s\n", $msg if $msg;

    my $count = '';
    if ( defined $ipmsg and @{ $ipmsg->message } ) {
        $count = sprintf " (%03d)", scalar @{ $ipmsg->message };
    }
    printf "ipmsg%s> ", $count;
}
