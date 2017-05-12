package SWF::BinStream::Codec::Zlib;

use strict;

$SWF::BinStream::Codec::Zlib::VERSION = "0.01";

package SWF::BinStream::Codec::Zlib::Read;

use Compress::Zlib;
use Carp;

sub new {
    my $z = inflateInit() or croak "Can't create zlib stream";
    bless \$z, shift;
}


sub decode {
    my ($self, $data) = @_;

    my ($out, $status) = $$self->inflate(\$data);
    defined $out or croak "Zlib raised an error $status";
    $out;
}

sub close {
}

package SWF::BinStream::Codec::Zlib::Write;

use Compress::Zlib;
use Carp;

sub new {
    my $z = deflateInit() or croak "Can't create zlib stream ";
    bless \$z, shift;
}


sub encode {
    my ($self, $data) = @_;

    my ($out, $status) = $$self->deflate(\$data);
    defined $out or croak "Zlib raised an error $status (wm)";
    $out;
}

sub close {
    my ($self, $data) = @_;
    my $z = $$self;
    my ($out, $out1, $status);

    if ($data ne '') {
	($out, $status) = $z->deflate(\$data);
	defined $out or croak "Zlib raised an error $status (wc1)";
    }
    ($out1, $status) = $z->flush;
    defined $out1 or croak "Zlib raised an error $status (wc2)";
    $out .= $out1;
}

1;
__END__

=head1 NAME

SWF::BinStream::Codec::Zlib - SWF::BinStream codec to add zlib-compression/decompression.

=head1 SYNOPSIS

  use SWF::BinStream;
  ..
  $stream->add_codec('Zlib');

=head1 DESCRIPTION

This is a module for SWF::BinStream to add zlib-compression/decompression.

=head1 COPYRIGHT

Copyright 2002 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SWF::BinStream>, L<SWF::BinStream::Codec>

=cut


