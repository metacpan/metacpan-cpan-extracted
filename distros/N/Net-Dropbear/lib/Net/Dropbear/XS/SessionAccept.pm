package Net::Dropbear::XS::SessionAccept;

use strict;
use warnings;

our $VERSION = '0.14';

1;
__END__

=encoding utf-8

=head1 NAME

Net::Dropbear::XS::SessionAccept - Manage how a command session should be
handled by Dropbear.

=head1 DESCRIPTION

This type of object is created and passed during the on_chansess_command hook.
See L<Net::Dropbear::SSHd> for details. There is no new method for this object,
it is only created based on the struct from Dropbear.

=head1 ATTRIBUTES

All of these attributes are set to a defaults. if C<HOOK_COMPLETE> is returned,
they should be filled in with enough information to allow Dropbear to clean
up afterwards. This means it will close file handles and send exit signals
to child processes.

=over 

=item channel_index 

The index of the channel being opened.  This is B<Read-Only>.

B<Default:> The current channel index

=item cmd

The command that will be ran.  This can be changed to a new command and
Dropbear will run the new command instead.

B<Default:> The requested command

=item pid

The pid of the child process

B<Default:> 0 (no child process)

=item iscmd

A boolean indicating that the request was for a command to be ran.

B<Default:> From the request

=item issubsys

A boolean indicating that this command was requesting a subsystem (SCP, SFTP,
etc).

B<Default:> From the request

=item writefd

The file descriptor number that this channel will write to. On a command,
this would be STDOUT.

B<Default:> -1 (file closed)


=item readfd

The file descriptor number that this channel will read from. On a command,
this would be STDIN.

B<Default:> -1 (file closed)

=item errfd

The file descriptor number that this channel will write error messages to.
On a command, this would be STDERR.

B<Default:> -1 (file closed)

=back

=cut
