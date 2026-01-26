package Plack::Handler::H2::Writer;

use strict;
use warnings;

sub new {
    my ($class, $response) = @_;
    return bless $response, $class;
}

sub write {
  my ($self, $chunk) = @_;
  my $writer = $self->{writer};
  $writer->(0, $chunk);  # 0 = don't end stream yet
}

sub close {
  my ($self) = @_;
  my $writer = $self->{writer};
  $writer->(1, undef);  # 1 = end stream
}

1;

__END__

=head1 NAME

Plack::Handler::H2::Writer - Streaming response writer for HTTP/2

=head1 SYNOPSIS

    # In your PSGI application using delayed/streaming responses
    my $app = sub {
        my $env = shift;
        
        return sub {
            my $responder = shift;
            
            # Send headers first
            my $writer = $responder->([
                200,
                ['Content-Type' => 'text/plain']
            ]);
            
            # Stream data chunks
            $writer->write("First chunk\n");
            $writer->write("Second chunk\n");
            $writer->write("Third chunk\n");
            
            # Close the stream
            $writer->close();
        };
    };

=head1 DESCRIPTION

C<Plack::Handler::H2::Writer> provides a streaming interface for sending HTTP/2 
response bodies in chunks. This is used internally by L<Plack::Handler::H2> to 
implement PSGI's streaming response protocol.

When your PSGI application returns a code reference (delayed response), it 
receives a responder callback. Calling this responder with a status and headers 
returns a writer object that allows you to send the response body in multiple 
chunks, which is particularly useful for:

=over 4

=item * Large responses that don't fit in memory

=item * Server-sent events

=item * Streaming data generation

=item * Progressive rendering

=back

=head1 METHODS

=head2 new

    my $writer = Plack::Handler::H2::Writer->new($response);

Constructor. This is called internally by the handler and should not be 
called directly by application code.

=head2 write

    $writer->write($chunk);

Writes a chunk of data to the HTTP/2 stream. The chunk should be a string 
of bytes. This method can be called multiple times to send data incrementally.

B<Parameters:>

=over 4

=item * C<$chunk> - A scalar containing the data to send

=back

B<Example:>

    $writer->write("Hello, ");
    $writer->write("world!\n");

=head2 close

    $writer->close();

Closes the HTTP/2 stream, signaling that no more data will be sent. You 
must call this method when you're done writing data, otherwise the client 
will wait indefinitely for more data.

After calling C<close()>, you should not call C<write()> again on the same 
writer object.

B<Example:>

    $writer->write("Final data");
    $writer->close();

=head1 HTTP/2 SPECIFICS

This writer integrates with HTTP/2's streaming model:

=over 4

=item * Each C<write()> call sends data with the HTTP/2 DATA frame

=item * The C<close()> method sends an END_STREAM flag

=item * Content-Length headers are automatically omitted for streaming responses

=item * Backpressure is handled by the HTTP/2 flow control mechanism

=back

=head1 SEE ALSO

L<Plack::Handler::H2>, L<PSGI>, L<Plack>

=head1 AUTHOR

Rawley Fowler E<lt>rawley@molluscsoftware.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the BSD 3-Clause License.

See the LICENSE file in the distribution for the full license text.

=cut