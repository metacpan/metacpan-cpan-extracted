#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Receipt.pm                                            #
#                                                                              #
# Description: Receipt support for Net::STOMP::Client                          #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Receipt;
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);

#
# return the list of not-yet-received receipts
#

sub receipts : method {
    my($self) = @_;
    my(@list);

    @list = keys(%{ $self->{"receipts"} }) if $self->{"receipts"};
    return(@list);
}

#
# wait for all receipts to be received
#

sub wait_for_receipts : method {
    my($self, %option) = @_;

    return(0) unless $self->receipts();
    $option{callback} = sub { return($self->receipts() == 0) };
    return($self->wait_for_frames(%option));
}

#
# hook for all client frames
#

sub _client_hook ($$) {
    my($self, $frame) = @_;
    my($value);

    $value = $frame->header("receipt");
    return unless defined($value);
    dief("duplicate receipt: %s", $value) if $self->{"receipts"}{$value}++;
}

#
# hook for the RECEIPT frame
#

sub _receipt_hook ($$) {
    my($self, $frame) = @_;
    my($value);

    $value = $frame->header("receipt-id");
    dief("missing receipt-id in RECEIPT frame") unless defined($value);
    dief("unexpected receipt: %s", $value)
        unless $self->{"receipts"} and $self->{"receipts"}{$value};
    delete($self->{"receipts"}{$value});
}

#
# register the hooks
#

foreach my $frame (qw(ABORT ACK BEGIN COMMIT DISCONNECT NACK
                      SEND SUBSCRIBE UNSUBSCRIBE)) {
    $Net::STOMP::Client::Hook{$frame}{"receipt"} = \&_client_hook;
}
$Net::STOMP::Client::Hook{"RECEIPT"}{"receipt"} = \&_receipt_hook;

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(receipts wait_for_receipts));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Receipt - Receipt support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client;
  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  ...
  # send two messages with receipts
  $stomp->send(
      destination => "/queue/test1",
      body        => "message 1",
      receipt     => $stomp->uuid(),
  );
  $stomp->send(
      destination => "/queue/test2",
      body        => "message 2",
      receipt     => $stomp->uuid(),
  );
  # wait for both acknowledgments to come back within ten seconds
  $stomp->wait_for_receipts(timeout => 10);
  die("Not all receipts received!\n") if $stomp->receipts();

=head1 DESCRIPTION

This module eases receipts handling. It is used internally by
L<Net::STOMP::Client> and should not be directly used elsewhere.

Each time a client frame is sent, its C<receipt> header (if supplied) is
remembered.

Each time a C<RECEIPT> frame is received from the server, the corresponding
receipt is ticked off.

The receipts() method can be used to get the list of outstanding receipts.

The wait_for_receipts() method can be used to wait for all missing receipts.

=head1 METHODS

This module provides the following methods to L<Net::STOMP::Client>:

=over

=item receipts()

get the list of not-yet-received receipts

=item wait_for_receipts([OPTIONS])

wait for all receipts to be received, using wait_for_frames() underneath;
take the same options as wait_for_frames(), except C<callback> which is
overridden

=back

=head1 SEE ALSO

L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
