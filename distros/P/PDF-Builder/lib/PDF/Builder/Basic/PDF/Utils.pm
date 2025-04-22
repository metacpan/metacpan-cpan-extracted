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
package PDF::Builder::Basic::PDF::Utils;

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Utils - Utility functions for PDF library

=head1 DESCRIPTION

A set of utility functions to save the fingers of the PDF library users!

=head1 METHODS

=cut

use PDF::Builder::Basic::PDF::Array;
use PDF::Builder::Basic::PDF::Bool;
use PDF::Builder::Basic::PDF::Dict;
use PDF::Builder::Basic::PDF::Name;
use PDF::Builder::Basic::PDF::Null;
use PDF::Builder::Basic::PDF::Number;
use PDF::Builder::Basic::PDF::String;
use PDF::Builder::Basic::PDF::Literal;

use Exporter;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(PDFBool PDFArray PDFDict PDFName PDFNull
             PDFNum PDFString PDFStr PDFStrHex PDFUtf);

=head2 PDFBool

    PDFBool()

=over

Creates a Bool via PDF::Builder::Basic::PDF::Bool->new()

=back

=cut

sub PDFBool {
    return PDF::Builder::Basic::PDF::Bool->new(@_);
}

=head2 PDFArray

    PDFArray()

=over

Creates an array via PDF::Builder::Basic::PDF::Array->new()

=back

=cut

sub PDFArray {
    return PDF::Builder::Basic::PDF::Array->new(@_);
}

=head2 PDFDict

    PDFDict()

=over

Creates a dict via PDF::Builder::Basic::PDF::Dict->new()

=back

=cut

sub PDFDict {
    return PDF::Builder::Basic::PDF::Dict->new(@_);
}

=head2 PDFName

    PDFName()

=over

Creates a name via PDF::Builder::Basic::PDF::Name->new()

=back

=cut

sub PDFName {
    return PDF::Builder::Basic::PDF::Name->new(@_);
}

=head2 PDFNull

    PDFNull()

=over

Creates a null via PDF::Builder::Basic::PDF::Null->new()

=back

=cut

sub PDFNull {
    return PDF::Builder::Basic::PDF::Null->new(@_);
}

=head2 PDFNum

    PDFNum()

=over

Creates a number via PDF::Builder::Basic::PDF::Number->new()

=back

=cut

sub PDFNum {
    return PDF::Builder::Basic::PDF::Number->new(@_);
}

=head2 PDFString

    PDFString($text, $usage)

=over

Returns either PDFStr($text) or PDFUtf($text), depending on whether C<$text>
is already in UTF-8 and whether the C<$usage> permits UTF-8. If UTF-8 is I<not>
permitted, C<downgrade> will be called on a UTF-8 formatted C<$text>.

C<$usage> is a single character string indicating the use for which C<$text>
is to be applied. Some uses permit UTF-8, while others (currently) forbid it:

=over

=item 's'

An ordinary B<string>, where UTF-8 text is permitted.

=item 'n'

A B<named destination>, where UTF-8 text is permitted.

=item 'o'

An B<outline title>, where UTF-8 text is permitted.

=item 'p'

A B<popup title>, where UTF-8 text is permitted.

=item 'm'

B<metadata>, where UTF-8 text is permitted.

=item 'f'

A B<file path and/or name>, where UTF-8 text is currently B<not> permitted.

=item 'u'

A B<URL>, where UTF-8 text is currently B<not> permitted.

=item 'x'

Any other usage where UTF-8 text is B<not> permitted.

=back

=back

=cut

sub PDFString {
    my ($text, $usage) = @_;

   # some old code also checked valid(), but that seems to always give a true
   #   return on non-UTF-8 text
   #my $isUTF8 = utf8::is_utf8($text) || utf8::valid($text);
    my $isUTF8 = utf8::is_utf8($text);
    my $isPermitted = 0;  # default NO
    # someone is bound to forget whether it's upper or lowercase!
    if ($usage =~ m/^[snopm]/i) { 
        $isPermitted = 1;
    }

    if ($isPermitted) { 
		if ($isUTF8) {
	    	return PDFUtf($text); 
        } else {
	    	return PDFStr($text); 
		}
    } else {
        if ($isUTF8) {
            utf8::downgrade($text); # force 7 bit ASCII
        }
	return PDFStr($text); 
    }
}

=head2 PDFStr

    PDFStr()

=over

Creates a string via PDF::Builder::Basic::PDF::String->new()

B<DEPRECATED.> It is preferable that you use C<PDFString> instead.

=back

=cut

sub PDFStr {
    return PDF::Builder::Basic::PDF::String->new(@_);
}

=head2 PDFStrHex

    PDFStrHex()

=over

Creates a hex-string via PDF::Builder::Basic::PDF::String->new()

=back

=cut

sub PDFStrHex {
    my $string = PDF::Builder::Basic::PDF::String->new(@_);
    $string->{' ishex'} = 1;
    return $string;
}

=head2 PDFUtf

    PDFUtf()

=over

Creates a utf8-string via PDF::Builder::Basic::PDF::String->new()

B<DEPRECATED.> It is preferable that you use C<PDFString> instead.

=back

=cut

sub PDFUtf {
    my $string = PDF::Builder::Basic::PDF::String->new(@_);
    $string->{' isutf'} = 1;
    return $string;
}

1;
