#!/usr/bin/perl -w
# $Id: remoteinteract.pl,v 1.1 2001/03/22 01:44:57 btrott Exp $

## remoteinteract.pl is an example of using Net::SSH::Perl to communicate
## interactively with a remote command. In this case, that command is the
## passwd command.
##
## Generally when executing a command that prompts you for information,
## you need to be interactive to respond to the prompts. Net::SSH::Perl
## allows you to register handlers for specific packet types that are sent
## to your client; in these handlers, you can check for recognizable
## prompts and act accordingly by sending a response (using a STDIN
## packet).
##
## remoteinteract.pl shows you how in an example of changing a password
## using the 'passwd' command. We check for three prompts: the prompt
## for the user's current password, the prompt for the new password, and
## the prompt for confirmation of the new password.
##
## You'll need to set the variables $host, $username, $new_password, and
## $old_password.
##
## Remember that this is just an example and should not be used without
## the addition of better error checking.

my($host, $username, $new_password, $old_password);

use strict;
use Net::SSH::Perl;

## We need to import the Constants module because we need the constant
## for the SSH_SMSG_STDERR_DATA and SSH_CMSG_STDIN_DATA packet types.
## Importing the :msg tag imports all of the SSH_xMSG constants.
##
## If we just wanted to import constants for the above two packet types,
## we could use this instead:
##
##     use Net::SSH::Perl::Constants qw(
##         SSH_SMSG_STDERR_DATA SSH_CMSG_STDIN_DATA
##     );
##
## It's more verbose, certainly, but it does cut down on the number of
## constants imported into our package.

use Net::SSH::Perl::Constants qw( :msg );

## Create a Net::SSH::Perl object and login to the remote host.

my $ssh = Net::SSH::Perl->new($host, debug => 1);
$ssh->login($username, $old_password);

## Register a handler routine for packets of type SSH_SMSG_STDERR_DATA.
## This routine will be called whenever the client loop (in
## Net::SSH::Perl) receives packets of this type. It will be given
## two arguments: the Net::SSH::Perl object, and the Net::SSH::Perl::Packet
## object that was received.
##
## We use get_str to get the contents of the STDERR message (because
## passwd writes its prompts to STDERR), then check those against the
## interactive prompts we expect.
##
## For each prompt, we send a packet of STDIN data, which is our response
## to the prompt. For example, when prompted for our current password,
## we send a packet containing that current password.
##
## NOTE: this does not include error checking, and thus should not be
## used wholesale.

$ssh->register_handler(SSH_SMSG_STDERR_DATA, sub {
    my($ssh, $packet) = @_;
    my $str = $packet->get_str;

    if ($str eq "(current) UNIX password: ") {
        my $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
        $packet->put_str($old_password);
        $packet->send;
    }

    elsif ($str eq "New UNIX password: ") {
        my $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
        $packet->put_str($new_password);
        $packet->send;
    }

    elsif ($str eq "Retype new UNIX password: ") {
        my $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
        $packet->put_str($new_password);
        $packet->send;
    }
});

## After registering the handler, we run the command.

$ssh->cmd('passwd');
