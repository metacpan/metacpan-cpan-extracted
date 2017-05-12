package String::UTF8::MD5;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Digest::MD5;
use Encode;
use base qw(Exporter);

our $EXPORT_OK = qw(md5);

=head1 NAME

String::UTF8::MD5 - UTF-8-safe md5sums of strings

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is a simple UTF8-safe wrapper around Crypt::MD5, for use with utf-8 strings.

use String::

=head1 EXPORT

=head2 md5 may be exported if requested

=head1 SUBROUTINES/METHODS

=head2 md5

=cut

sub md5 {
    my ($string) = @_;

    # remove utf-8 encoding
    if (Encode::is_utf8($string)) {
        $string = Encode::encode_utf8($string);
    }

    return Digest::MD5::md5_hex($string);
}

=head1 AUTHOR

Binary.com, C<< <cpan at binary.com> >>

=head1 TODO

Only hex notation is currently supported.  In the future we need to add additional
formatting options.

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-utf8-md5 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-UTF8-MD5>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::UTF8::MD5


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-UTF8-MD5>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-UTF8-MD5>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-UTF8-MD5>

=item * Search CPAN

L<http://search.cpan.org/dist/String-UTF8-MD5/>

=back


=head1 ACKNOWLEDGEMENTS



=cut

1;    # End of String::UTF8::MD5
