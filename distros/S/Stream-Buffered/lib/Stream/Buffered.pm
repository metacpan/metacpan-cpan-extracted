package Stream::Buffered;
use strict;
use warnings;

use FileHandle; # for seek etc.
use Stream::Buffered::Auto;
use Stream::Buffered::File;
use Stream::Buffered::PerlIO;

our $VERSION = 0.03;

our $MaxMemoryBufferSize = 1024 * 1024;

sub new {
    my($class, $length) = @_;

    # $MaxMemoryBufferSize = 0  -> Always temp file
    # $MaxMemoryBufferSize = -1 -> Always PerlIO
    my $backend;
    if ($MaxMemoryBufferSize < 0) {
        $backend = "PerlIO";
    } elsif ($MaxMemoryBufferSize == 0) {
        $backend = "File";
    } elsif (!$length) {
        $backend = "Auto";
    } elsif ($length > $MaxMemoryBufferSize) {
        $backend = "File";
    } else {
        $backend = "PerlIO";
    }

    $class->create($backend, $length, $MaxMemoryBufferSize);
}

sub create {
    my($class, $backend, $length, $max) = @_;
    (__PACKAGE__ . "::$backend")->new($length, $max);
}

sub print;
sub rewind;
sub size;

1;

__END__

=head1 NAME

Stream::Buffered - temporary buffer to save bytes

=head1 SYNOPSIS

  my $buf = Stream::Buffered->new($length);
  $buf->print($bytes);

  my $size = $buf->size;
  my $fh   = $buf->rewind;

=head1 DESCRIPTION

Stream::Buffered is a buffer class to store arbitrary length of byte
strings and then get a seekable filehandle once everything is
buffered. It uses PerlIO and/or temporary file to save the buffer
depending on the length of the size.

=head1 SEE ALSO

L<Plack::Request>

=head1 AUTHOR

Tatsuhiko Miyagawa

This module is part of L<Plack>, released as a separate distribution for easier
reuse.

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2009-2011 Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
