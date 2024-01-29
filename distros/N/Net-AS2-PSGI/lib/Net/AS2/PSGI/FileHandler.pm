package Net::AS2::PSGI::FileHandler;

use strict;
use warnings;
use autodie;
our $VERSION = '1.0001'; # VERSION

=head1 NAME

Net::AS2::PSGI::FileHandler - Provides methods to handle files being sent and received

=cut

use parent 'Net::AS2::PSGI::File';

=head1 METHODS

=over 4

=item = $self->receiving( $content, $receiving_dir )

This method is called when C<$content> is being received.

By default, this method stores the given content into a filename in the
RECEIVING directory as given by C<< $self->file($receiving_dir) >>.

I<Note> This method must B<not> be used to send an MDN response. It is
called immediately after the request has been received and before
the response has been sent back to the partner.

=cut

sub receiving {
    my ($self, $content, $receiving_dir) = @_;

    my $receiving_file = $self->file($receiving_dir);

    $self->write($receiving_file, $content);

    $self->logger(debug => "Receiving content saved in $receiving_file");

    return $receiving_file;

}

=item = $self->received( $receiving_file, $received_dir, $message )

This method is called when the content of C<$receiving_file> has been
received.  C<$message> is an object of class L<Net::AS2::Message>.

By default, this method renames the given C<$receiving_file> to a file
in the RECEIVED directory, calculated by C<< $self->file($received_dir, $ext) >>.
If the transfer was not successful, a file extension is calculated
from the state of the C<$message> object:

         State             Extension
 $message->is_success()     None
 $message->is_error()       .error
 $message->is_failure()     .failed

The received Content-Disposition header filename attribute is
available for use as C<< $message->filename() >>.

I<Note> This method must B<not> be used to send an MDN response. It is
called immediately after the request has been received and before
the response has been sent back to the partner.

=cut

sub received {
    my ($self, $receiving_file, $received_dir, $message) = @_;

    my $ext = $message->is_success ? '' : $message->is_error ? '.error' : '.failed';

    my $received_file = $self->file($received_dir, $ext);

    rename $receiving_file, $received_file;

    my $content_filename = $message->filename // '';

    $self->logger(debug => "Received '$content_filename' saved in file $received_file");

    return $received_file;

}

=item = $self->sending( $content, $sending_file )

This method is called when C<$content> is being sent.

By default, this method stores the given content into the
C<$sending_file>, which is calculated by C<< $self->file($sending_dir) >>.

=cut

sub sending {
    my ($self, $content, $sending_file) = @_;

    $self->write($sending_file, $content);

    $self->logger(debug => "Sending file $sending_file");

    return;

}

=item = $self->sent( $sending_file, $sent_dir, $successful )

This method is called when the content of C<$sending_file> has been sent.
C<$successful> is either a true or false value depending upon whether
the content was received by the partner successfully or not.

By default, this method renames the given C<$sending_file> to a file
in the SENT directory, calculated by C<< $self->file($sent_dir, $ext) >>.
If the transfer was not successful, a file extension, ".failed" is
used for C<$ext>.

=cut

sub sent {
    my ($self, $sending_file, $sent_dir, $successful) = @_;

    my $ext = $successful ? '' : '.failed';

    my $sent_file = $self->file($sent_dir, $ext);

    rename $sending_file, $sent_file;

    $self->logger(debug => "Sent file $sent_file");

    return;
}

=back

=cut


1;
