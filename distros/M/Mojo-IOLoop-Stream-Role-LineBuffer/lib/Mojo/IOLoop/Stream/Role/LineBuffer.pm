package Mojo::IOLoop::Stream::Role::LineBuffer;

use Mojo::Base -role;

our $VERSION = '0.002';

has 'read_line_separator' => sub { qr/\x0D?\x0A/ };
has 'write_line_separator' => "\x0D\x0A";

requires qw(on emit write);

sub watch_lines {
  my $self = shift;
  return $self if $self->{_read_line_read_cb};
  $self->{_read_line_read_cb} = $self->on(read => sub {
    my ($self, $bytes) = @_;
    $self->{_read_line_buffer} .= $bytes;
    my $sep = $self->read_line_separator;
    while ($self->{_read_line_buffer} =~ s/^(.*?)($sep)//s) {
      $self->emit(read_line => "$1", "$2");
    } continue {
      $sep = $self->read_line_separator;
    }
  });
  $self->{_read_line_close_cb} = $self->on(close => sub {
    my $self = shift;
    if (length(my $buffer = delete $self->{_read_line_buffer} // '')) {
      $self->emit(read_line => $buffer);
    }
  });
  return $self;
}

sub write_line {
  my ($self, $line) = (shift, shift);
  my $sep = $self->write_line_separator;
  $self->write("$line$sep", @_);
}

1;

=head1 NAME

Mojo::IOLoop::Stream::Role::LineBuffer - Read and write streams by lines

=head1 SYNOPSIS

  use Mojo::IOLoop;
  use Mojo::IOLoop::Stream;
  my $output_stream = Mojo::IOLoop::Stream->with_roles('+LineBuffer')->new($handle);
  Mojo::IOLoop->client({port => 3000} => sub {
    my ($loop, $err, $stream) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines->on(read_line => sub {
      my ($stream, $line) = @_;
      say "Received line: $line";
      $output_stream->write_line('Got it!');
    });
  });

=head1 DESCRIPTION

L<Mojo::IOLoop::Stream::Role::LineBuffer> composes the method
L</"watch_lines"> which causes a L<Mojo::IOLoop::Stream> object to emit the
L</"read_line"> event for each line received. The L</"write_line"> method is
also provided to add a line separator to the passed data before writing.

=head1 EVENTS

L<Mojo::IOLoop::Stream::Role::LineBuffer> can emit the following events.

=head2 read_line

  $stream->on(read_line => sub {
    my ($stream, $line, $separator) = @_;
    ...
  });

Emitted when a line ending in L</"read_line_separator"> arrives on the stream,
and when the stream closes if data is still buffered. The separator is passed
as a separate argument if present.

=head1 ATTRIBUTES

L<Mojo::IOLoop::Stream::Role::LineBuffer> composes the following attributes.

=head2 read_line_separator

  my $separator = $stream->read_line_separator;
  $stream       = $stream->read_line_separator(qr/\x0D\x0A/);

Regular expression to indicate new lines in received bytes. Defaults to a
newline (LF) character optionally preceded by a CR character (C<\x0D?\x0A>).
Note that if you set this to L<the generic newline|perlrebackslash/"\R"> or
C<\v> (vertical whitespace), this may match the CR character of a CR/LF
sequence and consider the LF as a separate line if they are read separately.

=head2 write_line_separator

  my $separator = $stream->write_line_separator;
  $stream       = $stream->write_line_separator("\x0A");

Byte sequence to indicate new lines in data written with L</"write_line">.
Defaults to the network newline CR/LF (C<\x0D\x0A>).

=head1 METHODS

L<Mojo::IOLoop::Stream::Role::LineBuffer> composes the following methods.

=head2 watch_lines

  $stream = $stream->watch_lines;

Subscribe to the L<Mojo::IOLoop::Stream/"read"> and
L<Mojo::IOLoop::Stream/"close"> events, to buffer received bytes and emit
L</"read_line"> when L</"read_line_separator"> is encountered or the stream is
closed with buffered data.

=head2 write_line

  $stream = $stream->write_line($bytes);
  $stream = $stream->write_line($bytes => sub {...});

Write a line to the stream by appending L</"write_line_separator"> to the data.
The optional drain callback will be executed once all data has been written.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::IOLoop::LineReader>, L<MojoX::LineStream>, L<POE::Filter::Line>,
L<IO::Async::Protocol::LineStream>
