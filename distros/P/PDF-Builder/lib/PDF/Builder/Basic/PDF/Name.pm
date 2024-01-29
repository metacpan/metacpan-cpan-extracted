#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#   Effective 28 January 2021, the original author and copyright holder, 
#   Martin Hosken, has given permission to use and redistribute this module 
#   under the MIT license.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Name;

use base 'PDF::Builder::Basic::PDF::String';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Name - Inherits from L<PDF::Builder::Basic::PDF::String>
and stores PDF names (things beginning with /)

=head1 METHODS

=head2 from_pdf

    $n = PDF::Builder::Basic::PDF::Name->from_pdf($string)

=over

Creates a new string object (not a full object yet) from a given
string. The string is parsed according to input criteria with
escaping working, particular to Names.

=back

=cut

sub from_pdf {
    my ($class, $string, $pdf) = @_;

    my ($self) = $class->SUPER::from_pdf($string);

    $self->{'val'} = name_to_string($self->{'val'}, $pdf);
    return $self;
}

=head2 convert

    $n->convert($string, $pdf)

=over

Converts a name into a string by removing the / and converting any hex
munging.

=back

=cut

sub convert {
    my ($self, $string, $pdf) = @_;

    $string = name_to_string($string, $pdf);
    return $string;
}

=head2 as_pdf

    $s->as_pdf($pdf)

=over

Returns a name formatted as PDF. C<$pdf> is optional but should be the
PDF File object for which the name is intended if supplied.

=back

=cut

sub as_pdf {
    my ($self, $pdf) = @_;

    my $string = $self->{'val'};

    $string = string_to_name($string, $pdf);
    return '/' . $string;
}


# Prior to PDF version 1.2, '#' was a literal character. Embedded
# spaces were implicitly allowed in names as well but it would be best
# to ignore that (PDF 1.3, section H.3.2.4.3).

=head2 string_to_name

    PDF::Builder::Basic::PDF::Name->string_to_name($string, $pdf)

=over

Suitably encode the string C<$string> for output in the File object C<$pdf>
(the exact format may depend on the version of $pdf).

=back

=cut

sub string_to_name {
    my ($string, $pdf) = @_;

    # PDF 1.0 and 1.1 didn't treat the # symbol as an escape character
    unless ($pdf and $pdf->{' version'} and $pdf->{' version'} < 1.2) {
        $string =~ s|([\x00-\x20\x7f-\xff%()\[\]{}<>#/])|'#' . sprintf('%02X', ord($1))|oge;
    }

    return $string;
}

=head2 name_to_string

    PDF::Builder::Basic::PDF::Name->name_to_string($string, $pdf)

=over

Suitably decode the string C<$string> as read from the File object C<$pdf>
(the exact decoding may depend on the version of $pdf).  Principally,
undo the hex encoding for PDF versions > 1.1.

=back

=cut

sub name_to_string {
    my ($string, $pdf) = @_;

    $string =~ s|^/||o;

    # PDF 1.0 and 1.1 didn't treat the # symbol as an escape character
    unless ($pdf and $pdf->{' version'} and $pdf->{' version'} < 1.2) {
        $string =~ s/#([0-9a-f]{2})/chr(hex($1))/oige;
    }

    return $string;
}

1;
