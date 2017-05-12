#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib  ../lib};
use Net::OBEX;

my $obex = Net::OBEX->new;

$obex->connect(
    address => '00:17:E3:37:76:BB',
    port    => 9,
    target  => 'F9EC7BC4953C11D2984E525400DC9E09', # OBEX FTP UUID
) or die "Failed to connect: " . $obex->error;

$obex->success
    or die "Server no liky :( " . $obex->status;

$obex->set_path
    or die "Error: " . $obex->error;

$obex->success
    or die "Server no liky :( " . $obex->status;

# this is an OBEX FTP example, so we'll get the folder listing now
my $response_ref = $obex->get( type => 'x-obex/folder-listing')
    or die "Error: " . $obex->error;

$obex->success
    or die "Server no liky :( " . $obex->status;

print "This is folder listing XML: \n$response_ref->{body}\n";

$obex->set_path( path => 'picture' )
    or die "Error: " . $obex->error;

$obex->success
    or die "Server no liky :( " . $obex->status;

open my $fh, '>', '22-02-08_2214.jpg'
    or die "Failed to open file ($!)";

$response_ref = $obex->get( name => '22-02-08_2214.jpg', file => $fh )
    or die "Error: " . $obex->error;

$obex->success
    or die "Server no liky :( " . $obex->status;

# send Disconnect packet with description header and close the socket
$obex->close('No want you no moar');
