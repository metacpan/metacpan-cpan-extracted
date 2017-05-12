package PerlIO::fgets;
use strict;
use warnings;

BEGIN {
    our $VERSION = '0.02';
    our @EXPORT  = qw[fgets];

    require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);

    require Exporter;
    *import = \&Exporter::import;
}

1;

__END__

=head1 NAME

PerlIO::fgets - Provides a C<fgets()> like function for PerlIO file handles

=head1 SYNOPSIS

    $octets = fgets(STDIN, 1024);
    $octets = fgets(*STDIN, 1024);
    $octets = fgets(\*STDIN, 1024);
    
    while ( ! eof($fh) ) {
        defined( $_ = fgets($fh, 1024) ) or die "fgets failed: $!";
        ...
    }
    

=head1 DESCRIPTION

Provides a C<fgets()> like function for PerlIO file handles

=head1 FUNCTIONS

=head2 fgets

Attempts to read a line from the given file handle C<$fh>.

I<Usage>

    $octets = fgets($fh, $maximum);

I<Arguments>

=over 4

=item C<$fh>

The file handle to read from. Must be a PerlIO file handle.

=item C<$maximum>

A positive integer containing the maximum number of octets to be read from 
the file handle (including the trailing newline character).

=back

I<Returns>

If C<fgets> encounters end-of-file before a newline or C<$maximum> octets 
read before a newline, it returns the octets. If C<fgets> reaches end-of-file 
before reading any octets, it returns an empty string. If unsuccessful, 
C<fgets> returns C<undef> and C<$!> contains the I/O error.

I<Note>

Unlike stdio's C<fgets()>, this implementation is not sensitive to input 
containing null characters.

=head1 EXPORTS

C<fgets>

=head1 LIMITATIONS

Current implementation has no understanding of Unicode (UTF-X), only octets.

=head1 PREREQUISITES

=head2 Run-Time

=over 4

=item L<perl> 5.8.1 or greater.

=item L<Exporter>, core module.

=back

=head2 Build-Time

In addition to Run-Time:

=over 4

=item C compiler.

=item L<IO::File>.

=item L<Test::More>

=item L<Test::HexString>.

=back

=head1 SEE ALSO

=over 4

=item L<File::GetLineMaxLength>.

=item L<File::fgets>.

=back

=head1 SUPPORT

Please report any bugs or feature requests to C<bug-perlio-fgets@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PerlIO-fgets>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

Copyright 2010 by Christian Hansen.

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

