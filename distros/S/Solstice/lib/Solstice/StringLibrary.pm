package Solstice::StringLibrary;

# $Id: StringLibrary.pm 2418 2005-07-28 23:28:31Z mcrawfor $

=head1 NAME

Solstice::StringLibrary - A library of generic string manipulation functions

=head1 SYNOPSIS

  use StringLibrary qw(truncstr);

  my $str = truncstr("This is a line of text that needs truncating.");

=head1 DESCRIPTION

Functions in this library make no assumptions about the content 
of the string being modified.

=cut

use 5.006_000;
use strict;
use warnings;
use HTML::Entities;
use HTML::TreeBuilder;
use HTML::FormatText;
use Solstice::StripScripts::Parser;
use Exporter;

our @ISA = qw(Exporter);
our ($VERSION) = ('$Revision: 2418 $' =~ /^\$Revision:\s*([\d.]*)/);

our @EXPORT = qw|htmltounicode truncstr truncemail fixstrlen encode decode unrender scrubhtml convertspaces strtoascii strtourl strtofilename strtojavascript trimstr htmltotext extracttext scrubcdata urlclean fixlinewidth|;
our %EXPORT_TAGS = ( all => [ qw|
    htmltounicode
    truncstr
    truncemail
    fixstrlen
    encode
    decode
    unrender
    scrubhtml
    convertspaces
    strtoascii
    strtourl
    strtofilename
    strtojavascript
    trimstr
    htmltotext
    extracttext
    scrubcdata
    urlclean
    fixlinewidth
| ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

=head2 Superclass

L<Exporter|Exporter>

=head2 Export

No symbols exported.

=head2 Functions

=over 4

=cut


=item htmltounicode($string)

Returns C<$string> with all E<amp>#234;-like unicode entities packed into perl
unicode.

=cut

sub htmltounicode {
    my ($string) = @_;
    return undef unless defined $string;
    $string =~ s/&#(\d*?);/pack('U*', $1)/ge;
    return $string;
}


=item scrubhtml ($string)

Returns $string with all malicious scripts, broken tags, relative links, dynamic css, etc removed.
=cut

sub scrubhtml {
    my ($string) = @_;
    return undef unless defined $string;

    my $parser = Solstice::StripScripts::Parser->new({
        AllowSrc     => 1,
        AllowHref    => 1,
        AllowNonHTTP => 1,
    });
    $parser->parse($string);
    $parser->eof;
    return $parser->filtered_document;
}

=item truncstr($string, $cutoff, $marker)

Returns $string truncated to $cutoff, and appended with an optional 
cutoff marker (defaults to '...').

=cut

sub truncstr {
    my ($string, $cutoff, $marker) = @_;
    return undef unless defined $string;
    $cutoff = 30 unless defined $cutoff;
    $marker = '...' unless defined $marker;
    
    return $string if (length($marker) > $cutoff);
    return $string if $cutoff < 0;

    if (length($string) > $cutoff) {
        $string = substr($string, 0, ($cutoff - length($marker))) ;
        $string .= $marker;
    }

    return $string;
}

=item truncemail($string, $left_limit, $right_limit, $marker)

Returns $string truncated to $left_limit characters to the left of
the first @ sign, $right_limit characters to the right of the last @
sign.  It will use $marker as the replacement.  Defaults are 20,
30 and '...'.

=cut

sub truncemail {
    my $string = shift;
    return unless defined $string;
    my $left_limit = shift || 20;
    my $right_limit = shift || 30;
    my $marker = shift || '...';

    return $string if ($left_limit < 0 || $right_limit < 0);
    return $string if (length ($string) < $left_limit + $right_limit + length($marker));

    my $left_side = substr($string, 0, $left_limit);
    my $right_side = substr($string, -1*$right_limit);

    $left_side =~ /^([^@]{1,$left_limit})/;
    $left_side = $1;

    $right_side =~ /([^@]{1,$right_limit})$/;;
    $right_side = $1;

    return $left_side.$marker.'@'.$marker.$right_side;
}

=item fixstrlen($string, $cutoff, $marker)

Returns a string of fixed-length. Strings shorter
than $cutoff are ignored. Strings longer than $cutoff are
transformed as in the following example:
Before: This is a long string of text that needs shortening
After: This is a long string o...ning

=cut

sub fixstrlen {
    my ($string, $cutoff, $marker) = @_;
    return undef unless defined $string;
    $cutoff = 30 unless defined $cutoff;
    $marker = '...' unless defined $marker;

    return '' if $cutoff <= 0;

    #if the cutoff is too short to do something clean, just force it
    return substr($string, 0, $cutoff) if ((length($marker) + 4) > $cutoff);

    if (length($string) > $cutoff) { 
        $string = substr($string, 0, $cutoff - (length($marker) + 4)) . $marker . substr($string, -4);
    }
    return $string;
}

=item fixlinewidth

Returns a string with breaking spaces inserted.

=cut

sub fixlinewidth {
    my ($string, $interval, $marker) = @_;
    
    return undef unless defined $string;
    $interval= 20 unless defined $interval;
    $marker = "<wbr />" unless defined $marker;
    
    return '' if $interval <= 0;
    $string =~   s/(\S{$interval})/$1$marker/g;

    return $string;
}

=item encode($string, $unsafe_chars)

Returns $string with HTML entities encoded. The string $unsafe_chars 
specifies which characters to consider unsafe (i.e., which to escape).
The default set of characters to encode are control chars, high-bit 
chars, and the <, &, >, ' and " characters. 
This function just wraps HTML::Entities::encode_entities.

=cut

sub encode {
    my ($string, $unsafe_chars) = @_;
    return HTML::Entities::encode_entities($string, $unsafe_chars);
}

=item decode($string)

Returns $string with HTML entities decoded. This function just wraps 
HTML::Entities::decode.

=cut

sub decode {
    my ($string) = @_;
    return HTML::Entities::decode($string);
}

=item unrender($string, $convert_whitespace)

Returns $string transformed into a non-HTML-renderable 
string, by converting '&<"' chars to entities. Numeric 
entities are ignored. If $convert_whitespace is passed
and is true, whitespace chars ' ', \t and \n are converted
to HTML approximations.

=cut

sub unrender {
    my ($string, $convert_whitespace)  = @_;
    return undef unless defined $string;

    $string =~ s/&([^#]{1})/&amp;$1/g;
    $string =~ s/</&lt;/g;
    $string =~ s/"/&quot;/g;
    
    return $string unless ($convert_whitespace);

    $string =~ s/\n/<br \/>/g;
    $string =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/g;
    
    return $string;
}

=item urlclean

Removes double slashes in urls

=cut

sub urlclean {
    my $url = shift;
    return $url unless $url;

    $url =~ s/\/+/\//g;
    $url =~ s/:\//:\/\//;
    return $url;
}



=item htmltotext($string)

$string should contain html.  Returns $string with html removed, and replaced with 
whitespace formatting.

        <ul>
eg:     <li>a   becomes:    * a
        <li>b               * b
        </ul>
=cut

sub htmltotext {
    my $string = shift;
    return undef unless defined $string;

    #oh lord, this string replacement thing is so nasty, but
    #one of these html libraries was mangling entities.
    $string =~ s/\&([^;]+)?;/SOLSTICE__REPLACE__TOKEN$1;/g;

    my $tree = HTML::TreeBuilder->new_from_content($string);
    my $formatter = new Solstice::StringLibrary::FormatText(leftmargin => 0, rightmargin => 55);
    $string = $formatter->format($tree);
    $tree->delete();

    $string =~ s/SOLSTICE__REPLACE__TOKEN/\&/g;
    $string =~ s/&nbsp;/ /g;
    return $string;
}

=item extracttext($string)

$string should contain html. Returns $string with html removed.

=cut

sub extracttext {
    my $string = shift;
    return undef unless defined $string;
     
    $string =~ s/\&([^;]+)?;/SOLSTICE__REPLACE__TOKEN$1;/g;

    my $tree = HTML::TreeBuilder->new_from_content($string);
    $string = Solstice::StringLibrary::ExtractText->new()->format($tree);
    $tree->delete();
    
    $string =~ s/SOLSTICE__REPLACE__TOKEN/\&/g;
    return $string;
}

=item convertspaces($string)

Returns $string transformed into a non-breaking HTML line by
replacing ' ' with '&nbsp;'.

=cut

sub convertspaces {
    my $string = shift;
    return undef unless defined $string;

    $string =~ s/ /&nbsp;/g;
    return $string;
}

=item strtoascii($string)

Changes certain characters (curly quotes,
emdash, endash) to their ASCII equivalent.

\x91 curly single quote left
\x92 curly single quote right
\x93 curly double quote left
\x94 curly double quote right
\x95 bullet point
\x96 emdash
\x97 endash
\xa9 copyright
\x85 elipses
• bullet point

=cut

sub strtoascii {
    my $string = shift;
    return undef unless defined $string;

    for ($string) {
        tr/\x91\x92\x93\x94\x95\x96\x97\xa9/''""*\-\-C/;
        s/•/*/g;
        s/\x85/.../g;
    }
    return $string;
}

=item strtourl($string)

Returns $string transformed into a safe url, by url-encoding non-word
characters.

=cut

sub strtourl {
    my $string = shift;
    return undef unless defined $string;

    $string =~ s/(\W)/sprintf("%%%x", ord($1))/eg;
    return $string;
}

=item strtofilename($string, $preserve_whitespace)

Returns $string transformed into a safe file name, by converting
spaces to underscores and removing forward slashes. $preserve_whitespace
specifies that whitespace should be escaped rather than translated.

=cut

sub strtofilename {
    my ($string, $preserve_whitespace) = @_;
    return undef unless defined $string;

    my $replace = ($preserve_whitespace) ? "\\ " : '_';    

    for ($string) {
        s/\s/$replace/g;
        s/[\/\?\<\>\\\:\*\|\)\(\']//g;
    }
    return $string;
}

=item strtojavascript($string)

Returns $string transformed into a javascript-safe string, by 
escaping single- and double-quote characters.

=cut

sub strtojavascript {
    my $string = shift;
    return undef unless defined $string;

    for ($string) {
        s/&#39;/'/g;
        #XXX well - removing this seems to clear up a lot of double-escaping we're seeing. hope it doesn't break anything.
#        s/\\/\\\\/g;
        s/"/\\"/g;
        s/'/\\'/g;
        s/[\n\r]//g;
    }
    return $string;
}

=item trimstr($string)

Remove leading and trailing whitespace from $string.

=cut

sub trimstr {
    my $string = shift;
    return undef unless defined $string;

    for ($string) {
        s/^(?:\s|&#09;|&#10;|&#13;|&#32;)+//;
        s/(?:\s|&#09;|&#10;|&#13;|&#32;)+$//;
    }
    return $string;
}

=item scrubcdata($string)

This will return a string with ]]> escaped, so it will be cdata safe.

=cut

sub scrubcdata {
    my $string = shift;
    return undef unless defined $string;

    $string =~ s/]]>/]]&gt;/g;
    return $string;
}


package Solstice::StringLibrary::ExtractText;

use base qw(HTML::Formatter);

## no critic 
#this little section is determined by a superclass, doesn't fit our style guidlines

sub pre_out {
    my $self = shift;
    my $text = shift;
    $self->collect($text);
}

sub out {
    my $self = shift;
    my $text = shift;
    unless ($text =~ /^\s*$/) {
        $self->collect($text.' ');
    }
}

sub img_start {
    my ($self, $node) = @_;
    my $alt = $node->attr('alt');
    $alt = (defined $alt && $alt ne '') ? ": $alt" : '';
    $self->collect('[IMAGE'.$alt.'] ');
}

sub adjust_lm {} 
sub adjust_rm {}

## use critic

#this exists just to remove the line that corrupts some text for us
package Solstice::StringLibrary::FormatText;

use base qw(HTML::FormatText);

sub out
{
    my $self = shift;
    my $text = shift;

    #here's the culprit
#    $text =~ tr/\xA0\xAD/ /d;

    if ($text =~ /^\s*$/) {
    $self->{hspace} = 1;
    return;
    }

    if (defined $self->{vspace}) {
    if ($self->{out}) {
        $self->nl while $self->{vspace}-- >= 0;
        }
    $self->goto_lm;
    $self->{vspace} = undef;
    $self->{hspace} = 0;
    }

    if ($self->{hspace}) {
        if ($self->{curpos} + length($text) > $self->{rm}) {
            # word will not fit on line; do a line break
            $self->nl;
            $self->goto_lm;
        } else {
            # word fits on line; use a space
            $self->collect(' ');
            ++$self->{curpos};
        }
        $self->{hspace} = 0;
    }

    $self->collect($text);
    my $pos = $self->{curpos} += length $text;
    $self->{maxpos} = $pos if $self->{maxpos} < $pos;
    $self->{'out'}++;
}


1;

__END__

=back

=head2 Modules Used

L<Exporter|Exporter>,
L<HTML::Entities|HTML::Entities>,
L<HTML::TreeBuilder|HTML::TreeBuilder>,
L<HTML::FormatText|HTML::FormatText>,
L<Solstice::StripScripts::Parser|Solstice::StripScripts::Parser>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2418 $ 



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
