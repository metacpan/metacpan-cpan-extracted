#!/usr/bin/perl -w
# $Id: remoteinteract2.pl,v 1.1 2001/08/29 08:24:57 btrott Exp $

## remoteinteract2.pl is an example of using Net::SSH::Perl to communicate
## interactively with a remote command. In this case, that command is the
## passwd command.
##
## The difference between this script and remoteinteract.pl is that this
## script uses the SSH-2 protocol and SSH-2 callbacks, whereas the other
## uses the SSH-1 protocol.
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

## Create a Net::SSH::Perl object and login to the remote host.
## NOTE: some versions of passwd require that your session be running
## on a tty, and not reading from STDIN. If your passwd is like this,
## you can use the "use_pty" parameter (set to 1) to the constructor
## to force the allocation of a TTY on the remote machine.

my $ssh = Net::SSH::Perl->new($host, debug => 1, protocol => 2);
$ssh->login($username, $old_password);

## Register a handler routine for STDERR data ("stderr").
## This routine will be called whenever the channel upon which we are
## running receives STDERR data. The callback will be given two arguments:
## the Net::SSH::Perl::Channel object, and a Net::SSH::Perl::Buffer
## object holding the data.
##
## We use buffer->bytes to get the contents of the STDERR message (because
## passwd writes its prompts to STDERR), then check those against the
## interactive prompts we expect.
##
## For each prompt, we send some data on the channel: the data to be sent
## is our response to the prompt. For example, when prompted for our
## current password, we send a packet containing that current password.
##
## NOTE: this does not include error checking, and thus should not be
## used wholesale. Note also that the prompts in my version of passwd
## may differ from those used in your version; so the prompts may require
## changes.

$ssh->register_handler("stderr", sub {
    my($channel, $buffer) = @_;
    my $str = $buffer->bytes;

    if ($str eq "(current) UNIX password: ") {
        $channel->send_data($old_password);
    }

    elsif ($str eq "New UNIX password: ") {
        $channel->send_data($new_password);
    }

    elsif ($str eq "Retype new UNIX password: ") {
        $channel->send_data($new_password);
    }
});

## After registering the handler, we run the command.

$ssh->cmd('passwd');
