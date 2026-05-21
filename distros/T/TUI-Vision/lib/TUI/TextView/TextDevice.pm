package TUI::TextView::TextDevice;
# ABSTRACT: Abstract text device class

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTextDevice
  new_TTextDevice
);

require bytes;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Views::Scroller;

sub TTextDevice() { __PACKAGE__ }
sub name() { 'TTextDevice' }
sub new_TTextDevice { __PACKAGE__->from(@_) }

extends TScroller;

# protected attributes
has opened    => ( is => 'ro', default => true );

# private attributes
has egress    => ( is => 'bare', default => '' );
has esize     => ( is => 'bare', default => 2048 );
has autoflush => ( is => 'bare', default => false );

# predeclare private methods
my (
  $append_to_egress
);

# TTextDevice streambuf interface

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Bool $in_global_destruction );
  unless ( $in_global_destruction ) {
    $self->close()
      if $self->opened();
  }
  return;
}

sub do_sputn {    # $num ($s, $count)
  state $sig = signature(
    method => Object,
    pos    => [Str, Int],
  );
  $sig->( @_ );
  ...
}

# B<Note>: only for compatibility
sub overflow {    # $int (|$c)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Int]],
  );
  my ( $self, $c ) = $sig->( @_ );
  $c //= -1;
  if ( $c != -1 ) {
    my $b = chr( $c );
    $self->do_sputn( $b, 1 );
  }
  return 1;
}

# IO::Handle interface

# C<autoflush> getter/setter
# B<Note>: turn on autoflush if no argument is given.
sub autoflush {    # $ (|$)
  state $sig = signature(
    method => Object,
    pos    => [Maybe[Bool], { optional => 1 }],
  );
  my ( $self, $value ) = $sig->( @_ );
  my $r = $self->{autoflush};
  $self->{autoflush} = !!( @_ > 1 ? $value : 1 );
  return $r;
}

sub close {    # $success ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return unless $self->opened();
  my $r = $self->flush();
  $self->{opened} = false;
  return $r;
}

# C<flush> method: write buffer and clear it.
# Returns C<"0 but true"> on success, undef on error.
sub flush {    # $success ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return 1 unless length $self->{egress};    # Nothing to flush
  my $data = $self->{egress};
  $self->{egress} = '';                      # Clear buffer
  return $self->syswrite( $data ) ? "0E0" : undef;
}

# Append data to the C<egress> buffer and L</flush> if size exceeds C<esize>
$append_to_egress = sub {    # void ($data)
  my ( $self, $data ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_Str $data );
  $self->{egress} .= $data;

  # Auto-flush if buffer exceeds esize
  if ( bytes::length( $self->{egress} ) >= $self->{esize} ) {
    $self->flush();
  }
  return;
};

sub print {    # $success (@list)
  state $sig = signature(
    method => Object,
    pos    => [
      ArrayRef, { slurpy => 1 },
    ],
  );
  my ( $self, $list ) = $sig->( @_ );
  $self->$append_to_egress( join( '', @$list ) );
  $self->flush() if $self->{autoflush};
  return 1;
}

sub printf {   # $success ($format, @list)
  state $sig = signature(
    method => Object,
    pos    => [
      Str, 
      ArrayRef, { slurpy => 1 },
    ],
  );
  my ( $self, $format, $list ) = $sig->( @_ );
  $self->$append_to_egress( sprintf( $format, @$list ) );
  $self->flush() if $self->{autoflush};
  return 1;
}

sub printflush {    # $success (@list)
  state $sig = signature(
    method => Object,
    pos    => [
      ArrayRef, { slurpy => 1 },
    ],
  );
  my ( $self, $list ) = $sig->( @_ );
  $self->$append_to_egress( join( '', @$list ) );
  return $self->flush();    # Force flush right now
}

sub say {    # $success (@list)
  state $sig = signature(
    method => Object,
    pos    => [
      ArrayRef, { slurpy => 1 },
    ],
  );
  my ( $self, $list ) = $sig->( @_ );
  $self->$append_to_egress( join( '', @$list ) . "\n" );
  $self->flush() if $self->{autoflush};
  return 1;
}

# The C<syswrite> method in Perl is the equivalent of L</do_sputn> in
# Borland's RTL. We need to call L</do_sputn> here to replicate the original 
# behavior.
sub syswrite {    # $num|undef ($, |$length, |$offset)
  state $sig = signature(
    method => Object,
    pos    => [
      Str,
      Int, { optional => 1 },
      Int, { optional => 1 },
    ],
  );
  my ( $self, $s, $len, $off ) = $sig->( @_ );
  $len //= bytes::length( $s );
  return $self->do_sputn(
    (
      defined( $len )
        ? bytes::substr( $s, $off || 0, $len )
        : $s
    ),
    $len
  );
} #/ sub syswrite

# always true

sub eof          { 1 }
sub ungetc       { 1 }
sub binmode      { 1 }

# always false

sub getc         { '' }
sub read         { '' }
sub error        { '' }
sub getline      { '' }

# abstract

sub new_from_fd  { ... }
sub fdopen       { ... }
sub fcntl        { ... }
sub format_write { ... }
sub ioctl        { ... }
sub stat         { ... }
sub truncate     { ... }
sub seek         { ... }
sub tell         { ... }
sub sync         { ... }
sub blocking     { ... }
sub sysseek      { ... }

# stubs for the other methods

sub write        { !!shift->syswrite(@_) }
sub getlines     { wantarray ? () : Carp::croak('called in a scalar context') }
sub fileno       { -1 }
sub clearerr     { 0 }
sub sysread      { 0 }

# tiehandle interface

sub TIEHANDLE { 
  ref($_[0]) 
    ? shift 
    : shift->new(@_)
}

sub GETC    { shift->getc(@_)     }
sub PRINT   { shift->print(@_)    }
sub PRINTF  { shift->printf(@_)   }
sub READ    { shift->read(@_)     }
sub WRITE   { shift->syswrite(@_) }
sub SEEK    { shift->seek(@_)     }
sub TELL    { shift->tell(@_)     }
sub EOF     { shift->eof()        }
sub CLOSE   { shift->close(@_)    }
sub BINMODE { shift->binmode(@_)  }

sub READLINE {
  wantarray 
    ? shift->getlines(@_) 
    : shift->getline(@_) 
}

1

__END__

=pod

=head1 NAME

TUI::TextView::TextDevice - abstract base class for text output devices

=head1 HIERARCHY

  TObject
    TView
      TScroller
        TTextDevice

=head1 DESCRIPTION

C<TTextDevice> is an abstract base class for text-based output devices in Turbo
Vision. It represents a scrollable, TTY-like text view and provides the common
infrastructure required by terminal-style views.

The class itself does not implement a concrete device. Instead, it defines a
minimal interface for reading and writing text buffers that must be implemented
by derived classes such as C<TTerminal>. In addition to the scrolling behavior
inherited from C<TScroller>, C<TTextDevice> integrates with Perl's
C<IO::Handle> interface and supports standard output methods such as
C<print>, C<printf>, and C<say>.

Most input-related methods are implemented as stubs and return fixed values.
Reading support must be provided explicitly by subclasses if required.

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors and are intended for
internal use by the text device implementation.

=over

=item opened

Indicates whether the device is considered open.  
This attribute defaults to true and is managed internally.

=back

The following attributes are private and not part of the public API. They are
documented here for completeness only.

=over

=item egress

Internal output buffer used for staged writes.

=item esize

Size of the internal output buffer (default: 2048 bytes).

=item autoflush

Boolean flag controlling whether output is flushed automatically after each
write operation.

=back

=head1 METHODS

=head2 new_TTextDevice

  my $device = new_TTextDevice($bounds, $aHScrollBar, $aVScrollBar);

Factory constructor for creating a new C<TTextDevice> instance. This constructor
delegates initialization to C<TScroller> and prepares the object for use as a
text output device.

=head2 autoflush

  my $value = $self->autoflush();
  $self->autoflush($value);

Gets or sets the autoflush flag. When enabled, output is flushed automatically
after each write operation.

=head2 do_sputn

  my $num = $self->do_sputn($string, $count);

Abstract output method used internally by C<syswrite>. Derived classes must
override this method to perform actual output operations.

=head2 print

  my $success = $self->print(@list);

Appends data to the device using C<syswrite> internally.

=head2 printf

  my $success = $self->printf($format, @list);

Formats data and appends it to the device using C<syswrite> internally.

=head2 say

  my $success = $self->say(@list);

Appends data followed by a newline and writes it to the device.

=head2 printflush

  my $success = $self->printflush(@list);

Appends data to the device and forces an immediate flush.

=head2 syswrite

  my $num | undef = $self->syswrite($scalar, | $length, | $offset);

Writes raw data to the device. This method delegates the actual output operation
to C<do_sputn> and mirrors the behavior of the original Turbo Vision runtime.

=head2 flush

  my $success | undef = $self->flush();

Flushes any buffered output. Returns C<"0 but true"> on success.

=head2 name

  my $name = $self->name();

Returns the class name (C<"TTextDevice">).

=head2 eof

  my $bool = $self->eof();

Indicates end-of-file. This implementation always returns true.

=head2 error

  my $bool = $self->error();

Returns the error state. This implementation always returns false.

=head2 clearerr

  my $value = $self->clearerr();

Clears the error state. This implementation performs no action.

=head2 read

  my $num = $self->read($buf, $len, | $offset);

Stub method for reading data. Always returns an empty result in this class.

=head2 getline

  my $line | undef = $self->getline();

Stub method for reading a line. Always returns an empty result.

=head2 getlines

  my @lines = $self->getlines();

Stub method for reading all lines. Always returns an empty list.

=head2 getc

  my $char = $self->getc();

Stub method for reading a single character.

=head2 ungetc

  my $success = $self->ungetc($ord);

Stub method for pushing a character back into the input stream.

=head2 binmode

  my $success = $self->binmode(| $layer);

Stub method for enabling binary mode. Always returns true.

=head2 blocking

  my $bool | undef = $self->blocking(| $bool);

Stub method for controlling blocking mode.

=head2 fileno

  my $fd = $self->fileno();

Returns the file descriptor number. Always returns C<-1>.

=head2 seek

  my $success = $self->seek($position, $whence);

Stub method for seeking.

=head2 tell

  my $pos = $self->tell();

Stub method for retrieving the current position.

=head2 truncate

  my $success = $self->truncate($length);

Stub method for truncating the device.

=head2 stat

  my @list = $self->stat();

Stub method for retrieving device statistics.

=head2 ioctl

  my $success = $self->ioctl($function, $scalar);

Stub method for device control operations.

=head2 fcntl

  my $success = $self->fcntl($function, $scalar);

Stub method for file control operations.

=head2 fdopen

  my $success = $self->fdopen($fd, $mode);

Stub method for opening a file descriptor.

=head2 new_from_fd

  my $obj = $self->new_from_fd();

Stub method for creating a device from a file descriptor. Always returns
C<undef>.

=head1 SEE ALSO

L<TUI::TextView::Terminal>, L<TUI::Views::Scroller>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
