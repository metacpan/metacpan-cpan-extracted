#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use Test::More tests => 6;
use Test::Exception;
use Test::Output;

use IO::Socket;

use Readonly;

Readonly my $PORT             => 2255;
Readonly my $HOST             => '127.0.0.1';
Readonly my $HEADER_LENGTH    => 16;
Readonly my $ENQUIRE_INTERVAL => 2;
Readonly my $SEND_INTERVAL    => 4;
Readonly my $DEFAULT_SLEEP    => 1;

my $client_pid;
local $SIG{'ALRM'} = sub { return; };
local $SIG{'PIPE'} = 'IGNORE';

my $header = q{};

use_ok('Net::SMPP')
    or croak 'Cannot load module Net::SMPP. No further testing done';

can_ok( 'Net::SMPP', 'read_hard' );

# Set trace variable to catch "ENQUIRE alarm" output.
no warnings;
$Net::SMPP::trace = 1;
use warnings;

#
# Start listener:
#
my $smpp = Net::SMPP->new_listen(
    $HOST,
    port => $PORT,
);

isa_ok( $smpp, 'Net::SMPP' );
isa_ok( $smpp, 'IO::Socket::INET' );
${*$smpp}{'enquire_interval'} = $ENQUIRE_INTERVAL;


#
# Start client:
#
sleep $DEFAULT_SLEEP;
system "./client.pl $PORT $SEND_INTERVAL &";
sleep $DEFAULT_SLEEP;

# Get client PID:
#open my $fh, '<', 'client.pid'
#    or croak "Cannot open pid file";
#$client_pid = <$fh>;
#chomp $client_pid;
#close $fh
#    or croak "Cannot close pid file";

#note("client started with PID $client_pid");

my $server = $smpp->accept();
ok( $server->connected(), 'server has connection' );


#
# Check STDERR for "ENQUIRE alarm":
#
note( 'waiting for alarm ( ~ ' . $ENQUIRE_INTERVAL * 2 . ' s) ...' );
stderr_like( sub { $server->read_hard( $HEADER_LENGTH, \$header, 0 ) },
    qr{ENQUIRE[ ]alarm}xms, 'alarm triggered' );

