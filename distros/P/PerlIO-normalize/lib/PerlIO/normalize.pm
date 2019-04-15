use strict;
use warnings;
package PerlIO::normalize;
# ABSTRACT: PerlIO layer to normalize unicode strings on input and output
$PerlIO::normalize::VERSION = '0.002';
use Unicode::Normalize;

require XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlIO::normalize - PerlIO layer to normalize unicode strings on input and output

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 # also enables UTF-8 decoding/encoding
 open my $fh, '<:encoding(UTF-8):normalize(NFD)', $file
   or die "Could not open $file for reading: $!";
 binmode STDOUT, ':normalize(NFC):encoding(UTF-8)';

=head1 DESCRIPTION

This L<PerlIO> layer uses L<Unicode::Normalize> to normalize the text read from
or written to a file-handle according to Unicode rules. It supports the
following normalization forms: C<NFC>, C<NFD>, C<NFKC>, C<NFKD>, C<FCC>, and
C<FCD>. It expects to recieve already-decoded unicode characters, so you should
make sure to put the correct encoding layer ahead of it if reading, and behind
it if writing, as per the SYNOPSIS.

=head1 SEE ALSO

=over 4

=item * L<PerlIO>

=item * L<PerlIO::encoding>

=item * L<PerlIO::utf8_strict>

=item * L<Unicode::Normalize>

=back

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
