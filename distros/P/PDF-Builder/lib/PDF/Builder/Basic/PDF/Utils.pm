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
#
#=======================================================================
package PDF::Builder::Basic::PDF::Utils;

use strict;
use warnings;

our $VERSION = '3.012'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Basic::PDF::Utils - Utility functions for PDF library

=head1 DESCRIPTION

A set of utility functions to save the fingers of the PDF library users!

=head1 FUNCTIONS

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
             PDFNum PDFStr PDFStrHex PDFUtf);

=head2 PDFBool()

Creates a Bool via PDF::Builder::Basic::PDF::Bool->new()

=cut

sub PDFBool {
    return PDF::Builder::Basic::PDF::Bool->new(@_);
}

=head2 PDFArray()

Creates an array via PDF::Builder::Basic::PDF::Array->new()

=cut

sub PDFArray {
    return PDF::Builder::Basic::PDF::Array->new(@_);
}

=head2 PDFDict()

Creates a dict via PDF::Builder::Basic::PDF::Dict->new()

=cut

sub PDFDict {
    return PDF::Builder::Basic::PDF::Dict->new(@_);
}

=head2 PDFName()

Creates a name via PDF::Builder::Basic::PDF::Name->new()

=cut

sub PDFName {
    return PDF::Builder::Basic::PDF::Name->new(@_);
}

=head2 PDFNull()

Creates a null via PDF::Builder::Basic::PDF::Null->new()

=cut

sub PDFNull {
    return PDF::Builder::Basic::PDF::Null->new(@_);
}

=head2 PDFNum()

Creates a number via PDF::Builder::Basic::PDF::Number->new()

=cut

sub PDFNum {
    return PDF::Builder::Basic::PDF::Number->new(@_);
}

=head2 PDFStr()

Creates a string via PDF::Builder::Basic::PDF::String->new()

=cut

sub PDFStr {
    return PDF::Builder::Basic::PDF::String->new(@_);
}

=head2 PDFStrHex()

Creates a hex-string via PDF::Builder::Basic::PDF::String->new()

=cut

sub PDFStrHex {
    my $string = PDF::Builder::Basic::PDF::String->new(@_);
    $string->{' ishex'} = 1;
    return $string;
}

=head2 PDFUtf()

Creates a utf8-string via PDF::Builder::Basic::PDF::String->new()

=cut

sub PDFUtf {
    my $string = PDF::Builder::Basic::PDF::String->new(@_);
    $string->{' isutf'} = 1;
    return $string;
}

1;
