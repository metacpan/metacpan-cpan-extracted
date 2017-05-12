package SMS::Handler::Dispatcher;

require 5.005_62;

use Carp;
use strict;
use warnings;
use SMS::Handler;
use SMS::Handler::Utils;

our $Debug = 0;

# $Id: Dispatcher.pm,v 1.4 2003/03/13 20:41:54 lem Exp $

our $VERSION = q$Revision: 1.4 $;
$VERSION =~ s/Revision: //;

=pod

=head1 NAME

SMS::Handler::Dispatcher - Helper class for dispatch - based SMS handlers

=head1 SYNOPSIS

  use SMS::Handler::Dispatcher;
  package MyHandler;
  @ISA = qw(SMS::Handler::Dispatcher);

  ...

=head1 DESCRIPTION

This module provides a base class that implements a dispatch table
based on the commands contained in the given SMS. Commands consist of
words (sequences of characters matching C<\w>) or its abbreviations
preceded by a single dot.

=pod

The following methods are provided:

=over 4

=pod

=item C<-E<gt>handle()>

Dispatch the required command to the handlers set up by the invoking
class. The command to method mapping is assumed to be supplied by the
object when calling C<-E<gt>abbrevs> (for the command abbreviations)
or C<-E<gt>cmds> for the command mapping. C<-E<gt>abbrevs> must return
a reference to a hash where each key is a possible command
abbreviation andd its value, is the actual command.

C<-E<gt>cmds> must return a reference to a hash, where each key is a
command and each value is a reference to the corresponding method to
call. This class includes dummy methods that simply return
C<-E<gt>{abbrevs}> or C<-E<gt>{cmds}> respectively.

Each of the methods implementing a command, will be called with the
following arguments.

=over 3

=item *

A reference to the object.

=item *

The hash reference passed to C<-E<gt>handle>.

=item *

A compact representation of the source address, made from
concatenating the NPI, TON and SOURCE with dots.

=item *

A reference to the command line of the SMS (or the whole SMS if no
separate lines).

=item *

A reference to the remainder of the SMS.

=back

A positive return value from said methods, tell C<-E<gt>handle> to
keep looking for commands. A false return value, stops the search for
further commands. In any case, C<-E<gt>handle> will return C<SMS_STOP
| SMS_DEQUEUE>.

If no corresponding command can be found for a given SMS, the
C<-E<gt>dispatch_error> method will be invoked, using the same calling
protocol than command methods. Its return value will be returned by
C<-E<gt>handle>.

The calling protocol depicted above is only attempted if the object
contains C<$self-E<gt>{number}>. In this case, the SMS destination
address is matched against C<$self-<gt>{dest_addr_ton}>,
C<$self-<gt>{dest_addr_npi}> and
C<$self-<gt>{dest_addr_destination_addr}>. Only if this match
succeeds, the message is accepted. This allows an object to restrict
the numbers it handles. C<SMS_CONTINUE> is returned in this case, to
allow other objects a chance to process this message.

=cut

sub handle
{
    my $self = shift;
    my $hsms = shift;

    if ($self->{number})
    {
	unless ($hsms->{dest_addr_ton} == $self->{ton})
	{
	    warn "Email: Destination address did not match TON\n" if $Debug;
	    return SMS_CONTINUE;
	}
        unless ($hsms->{dest_addr_npi} == $self->{npi})
	{
	    warn "Email: Destination address did not match NPI\n" if $Debug;
	    return SMS_CONTINUE;
	}
	unless ($hsms->{destination_addr} == $self->{number})
	{
	    warn "Email: Destination address did not match NUMBER\n" if $Debug;
	    return SMS_CONTINUE;
	}
    }
				# This is a convenient shortcut for the
				# source address

    my $source = join('.', $hsms->{source_addr_ton}, 
		      $hsms->{source_addr_npi}, 
		      $hsms->{source_addr});

    my $msg = $hsms->{short_message};
    my $body;

    ($msg, $body) = SMS::Handler::Utils::Split($msg);
				# $msg contains the first line of the SMS,
				# where we must look for commands.
				# We will look for a command keyword and
				# hand the whole thing to the corresponding
				# handler method

    $msg =~ s/^[^\.]+//;	# Remove any potential garbage before the
				# first dot.

    $msg =~ s/\s+$//;		# Remove trailing whitespace

    while ($msg =~ m/^\.(\w+)/)
    {
	warn "Dispatcher: Looking for command for '$1'\n" if $Debug;
	if ($self->cmds->{uc $1})
	{
	    warn "Dispatcher: command found\n" if $Debug;
	    last unless $self->cmds->{uc $1}->($self, $hsms, 
					       $source, \$msg, 
					       \$body);
	}
	else
	{
	    my $name = $self->abbrevs->{uc $1} || undef;
	    last unless $name;

	    warn "Dispatcher: match with $name\n" if $Debug;

	    last unless $self->cmds->{$name}->($self, $hsms, $source, 
					       \$msg, \$body);
	}
    }

    $msg =~ s/^\s+$//;		# Discard void whitespace
    
    if ($msg)
    {
	warn "Dispatcher: no match\n" if $Debug;
	return $self->dispatch_error($hsms, $source, \$msg, \$body);
    }

    return SMS_STOP | SMS_DEQUEUE;
}

=pod

=item C<-E<gt>dispatch_error>

sub dispatch_error
{
    croak "Classes based on SMS::Handler::Dispatcher must implement their dispatch_method()\n";
}

=cut

=pod

=item C<-E<gt>abbrevs>

Return C<$self->{abbrevs}>.

=cut

sub abbrevs { return $_[0]->{abbrevs}; }

=item C<-E<gt>cmds>

Return C<$self->{cmds}>.

=cut

sub cmds { return $_[0]->{cmds}; }

1;

__END__

=pod

=back

=head2 EXPORT

None by default.

=head1 LICENSE AND WARRANTY

This code comes with no warranty of any kind. The author cannot be
held liable for anything arising of the use of this code under no
circumstances.

This code is released under the terms and conditions of the
GPL. Please see the file LICENSE that accompains this distribution for
more specific information.

This code is (c) 2002 Luis E. Muñoz.

=head1 HISTORY

$Log: Dispatcher.pm,v $
Revision 1.4  2003/03/13 20:41:54  lem
Fixed case where a command was not followed by any options or any whitespace

Revision 1.3  2003/01/08 02:39:03  lem
Body was not being updated by _CMD_SEND. "Nokia" format send command is now properly understood. First segment of the message is being sent by .FORWARD and .REPLY.

Revision 1.2  2003/01/03 00:17:00  lem
Documented the address matching in ::Dispatch. Added a few more tests.

Revision 1.1  2002/12/27 19:43:42  lem
Added ::Dispatcher and ::Utils to better distribute code. This should make easier the writting of new methods easier


=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<SMS::Handler>, perl(1).

=cut



