package SMS::Handler;

require 5.005_62;

use Carp;
use strict;
use warnings;

# $Id: Handler.pm,v 1.7 2003/01/14 20:32:34 lem Exp $

our $VERSION = '0.01';

=pod

=head1 NAME

SMS::Handler - Base class for processing SMS messages in sms-agent

=head1 SYNOPSIS

  use SMS::Handler;

=head1 DESCRIPTION

This module implements the base implementation (virtual class) for a
class that processes SMS messages.

SMS messages will be passed as a hash reference, which contains the
following keys.

=over 2

=item C<source_addr_ton>

The TON for the source address of the SMS.

=item C<source_addr_npi>

The NPI for the source address of the SMS.

=item C<source_addr>

The source address.

=item C<dest_addr_ton>

The TON for the destination address of the SMS.

=item C<dest_addr_npi>

The NPI for the destination address of the SMS.

=item C<destination_addr>

The destination address.

=item C<short_message>

The actual SMS.

=back

The hash reference will be passed to a method called C<-E<gt>handle>,
which derived classes are expected to implement. This method must
return the following OR-ed values to indicate the required action on
the SMS.

=cut

sub handle 
{
    croak "SMS::Handler::handle is a virtual function\n";
}

=pod

=over 4

=item C<SMS_CONTINUE>

Causes the next handler in sequence to be tried.

=cut

use constant SMS_CONTINUE => 0x00;

=pod

=item C<SMS_STOP>

Tells C<sms-agent> to stop trying to look for another handler to
process the SMS. If this value is not ORed in the return of the
method, the next handler in sequence is tried.

=cut

use constant SMS_STOP	=> 0x01;

=item C<SMS_DEQUEUE>

Tells C<sms-agent> to remove the SMS from any queue it may have the
message in. Normally this is done on success.

=cut

use constant SMS_DEQUEUE => 0x02;

=pod

=back

Normally, you want to use C<SMS_STOP> whenever you produce a final
answer. You probably want to add C<SMS_DEQUEUE> too.

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
		 SMS_CONTINUE
		 SMS_STOP
		 SMS_DEQUEUE
		 );

sub new {
    croak 
	"SMS::Handler is meant as a base class. This is a virtual function.\n";
}

1;
__END__

=pod

=head2 Sample Event Loop

Derived classes should be used through an event loop as depicted below:    

    while (1)
    {
	my $sms = wait_sms_hash();
	
	for my $h (@List_Of_Handlers)
	{
	    my $ret = $h->handle($sms);
	    if ($ret & SMS_DEQUEUE)
	    {
				# Get rid of this SMS.
	    }
	    last if ($ret & SMS_STOP);
	}
    }

Where C<wait_sms_hash()> should produce a hash with the appropiate key
/ value pairs. Tipically, either C<Net::SMPP::XML> or C<Net::SMPP>
1.04 or greater should be of great help here if you want to fetch and
store C<Net::SMPP::PDU>s in some form of stable storage or queue.

=head2 EXPORT

None by default.


=head1 HISTORY

$Id: Handler.pm,v 1.7 2003/01/14 20:32:34 lem Exp $

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	SMS::Handler
	-v
	0.01

=back

=head1 LICENSE AND WARRANTY

This code comes with no warranty of any kind. The author cannot be
held liable for anything arising of the use of this code under no
circumstances.

This code is released under the terms and conditions of the
GPL. Please see the file LICENSE that accompains this distribution for
more specific information.

This code is (c) 2002 Luis E. Muñoz.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<sms-agent>, L<Net::SMPP::XML>, L<Net::SMPP>, perl(1).

=cut


