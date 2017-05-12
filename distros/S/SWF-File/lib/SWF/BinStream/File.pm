package SWF::BinStream::File;

use strict;
use vars qw($VERSION);
use SWF::BinStream;

$VERSION = '0.043';

package SWF::BinStream::File::Read;

use Carp;
use vars qw(@ISA);

@ISA = ('SWF::BinStream::Read');

sub new {
    my ($class, $file, $version) = @_;

    my $self = $class->SUPER::new('', \&_readfile, $version);
    $self->open($file) if defined $file;
    $self;
}

sub _readfile {
    my ($self, $bytes) = @_;
    my $file = $self->{_file};
    my $count = 0;

    return 0 unless defined $file;
    while (not eof($file) and $count < $bytes) {
	my $data;
	$count += read($file, $data, 1024);
	$self->SUPER::add_stream($data);
    }
    return ($count >= $bytes);
}

sub open {
    my ($self, $file) = @_;

    $self->close if defined $self->{_file};
    unless (ref($file) or $file =~ /^\*[\w:]+$/) {
	# Assume $file is a filename
	local *F;
	open(F, $file) or croak "Can't open $file: $!";
	$file = *F;
    }
    binmode $file;
    $self->{_file} = $file;
    $self;
}

sub close {
    my $self = shift;
    my $res;

    $self->close;
    $res = close $self->{_file} if defined $self->{_file};
    undef $self->{_file};
    $res;
}

sub add_stream {
    croak "Can't add data to a file stream ";
}

sub DESTROY {
    shift->close;
}

#####

package SWF::BinStream::File::Write;

use Carp;
use vars qw(@ISA);

@ISA = ('SWF::BinStream::Write');

sub new {
    my ($class, $file, $version) = @_;

    my $self = $class->SUPER::new($version);
    $self->SUPER::autoflush(1024, \&_writefile);
    $self->open($file) if defined $file;
    $self;
}

sub _writefile {
    my ($self, $data) = @_;
    my $file = $self->{_file};

    croak "The file to write has not opened " unless defined $file;
    print $file $data;
}

sub open {
    my ($self, $file) = @_;

    $self->close if defined $self->{_file};
    unless (ref($file) or $file =~ /^\*[\w:]+$/) {
	# Assume $file is a filename
	local *F;
	open(F, '>', $file) or croak "Can't open $file: $!";
	$file = *F;
    }
    binmode $file;
    $self->{_file} = $file;
    $self;
}

sub close {
    my $self = shift;
    my $file = $self->{_file};
    my $res;

    if (defined $file) {
	$self->SUPER::close;
	$res = close $file;
	undef $self->{_file};
    }
    $res;
}

sub autoflush {
}

sub DESTROY {
    shift->close;
}

1;
__END__

=head1 NAME

SWF::BinStream::File - Read and write file as binary stream.

=head1 SYNOPSIS

  use SWF::BinStream::File;

  $read_file = SWF::BinStream::File::Read->new('test.swf');
  $byte = $read_file->get_UI8;
  ....
  $read_file->close;

  $write_file = SWF::BinStream::Write->new('new.swf');
  $write_file->set_UI8($byte);
  ....
  $write_file->close;

=head1 DESCRIPTION

I<SWF::BinStream::File> module provides reading and writing binary
files as a binary stream.

=head2 SWF::BinStream::File::Read

is a subclass of SWF::BinStream::Read. You can get byte and bit
data from files.

=head2 METHODS

You can use the methods of I<SWF::BinStream::Read> except I<add_atream>.

=over 4

=item SWF::BinStream::File::Read->new( [ $file, $version ] )

creates a read stream connected with I<$file>.  
I<$file> is a file name or a file handle.  
I<$version> is SWF version number.  Default is 5.

=item $stream->open( $file )

opens another file and connect to the stream.
Even though the previous file is automatically closed
and the stream is cleared, I<$stream-E<gt>tell> number is
continued.

=item $stream->close

closes the file and clears the stream.

=back

=head2 SWF::BinStream::File::Write

is a subclass of SWF::BinStream::Write. You can write byte and bit
data to a file.

=head2 METHODS

You can use the methods of I<SWF::BinStream::Write> except I<autoflush>.

=over 4

=item SWF::BinStream::File::Write->new( [ $file, $version ] )

creates a stream writing to a file I<$file>.  
I<$file> is a file name or a file handle.  
I<$version> is SWF version number.  Default is 5.

=item $stream->open( $file )

opens another file and connect to the stream.
The stream is flushed and the previous file is closed.

=item $stream->close

flushes the stream and closes the file.

=back

=head1 COPYRIGHT

Copyright 2001 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SWF::BinStream>

=cut
