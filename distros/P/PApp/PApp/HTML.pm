##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::HTML - utility functions for html generation

=head1 SYNOPSIS

  use PApp::HTML;

=head1 DESCRIPTION

This module provides a host of HTML-related convenience functions, most of
which output HTML elements.

=cut

package PApp::HTML;

use Carp;
use FileHandle ();

use PApp::Util;

use base "Exporter";

use utf8;
no bytes;

use common::sense;

our $VERSION = 2.4;
our @EXPORT = qw(

      errbox

      xmltag tag

      alink mailto_url filefield param submit textfield password_field
      textarea escape_html escape_uri escape_attr hidden unixtime2http
      checkbox radio reset_button submit_image selectbox optiontag javascript button
);

=head1 Functions

=over 4

=item escape_html $arg

Returns the html-escaped version of C<$arg> (escaping characters like '<'
and '&', as well as any whitespace characters other than space, cr and
lf).

=item escape_uri $arg

Returns the uri-escaped version of C<$arg>, escaping characters like ' '
(space) and ';' into url-escaped-form using %hex-code. This function
encodes characters with code >255 as utf-8 characters.

=item escape_attr $arg

Returns the attribute-escaped version of C<$arg> (it also wraps its
argument into single quotes, so don't do that yourself).

=cut

our @HTML_ESCAPE;

$HTML_ESCAPE[$_] = sprintf "&lt;illegal character 0x%02x&gt;", $_
   for 0x00..0x08, 0x0b, 0x0d..0x1f;

$HTML_ESCAPE[ord "&"] = "&#38;";
$HTML_ESCAPE[ord "<"] = "&#60;";
$HTML_ESCAPE[ord ">"] = "&#62;";

# windows 1252 defines these, and of course microsoft uses their own
# encoding in place of unicode. We try to fix up here, but preserve the data.
$HTML_ESCAPE[128] = "&#x20ac;";
$HTML_ESCAPE[130] = "&#x201a;";
$HTML_ESCAPE[131] = "&#x0192;";
$HTML_ESCAPE[132] = "&#x201e;";
$HTML_ESCAPE[133] = "&#x2026;";
$HTML_ESCAPE[134] = "&#x2020;";
$HTML_ESCAPE[135] = "&#x2021;";
$HTML_ESCAPE[136] = "&#x02c6;";
$HTML_ESCAPE[137] = "&#x2030;";
$HTML_ESCAPE[138] = "&#x0160;";
$HTML_ESCAPE[139] = "&#x2039;";
$HTML_ESCAPE[140] = "&#x0152;";
$HTML_ESCAPE[142] = "&#x017d;";
$HTML_ESCAPE[145] = "&#x2018;";
$HTML_ESCAPE[146] = "&#x2019;";
$HTML_ESCAPE[147] = "&#x201c;";
$HTML_ESCAPE[148] = "&#x201d;";
$HTML_ESCAPE[149] = "&#x2022;";
$HTML_ESCAPE[150] = "&#x2013;";
$HTML_ESCAPE[151] = "&#x2014;";
$HTML_ESCAPE[152] = "&#x02dc;";
$HTML_ESCAPE[153] = "&#x2122;";
$HTML_ESCAPE[154] = "&#x0161;";
$HTML_ESCAPE[155] = "&#x203a;";
$HTML_ESCAPE[156] = "&#x0153;";
$HTML_ESCAPE[158] = "&#x017e;";
$HTML_ESCAPE[159] = "&#x0178;";

# clueless p5p's have removed /o without similar performant alternative
our $HTML_ESCAPE = qr<([${\(join "", map { sprintf "\\x%02x", $_ } grep defined $HTML_ESCAPE[$_], 0..$#HTML_ESCAPE)}])>;

sub escape_html($) {
   shift =~ s/$HTML_ESCAPE/$HTML_ESCAPE[ord $1]/gr
}

sub escape_uri($) {
   my $str = shift;
   utf8::encode $str;
   $str =~ s/([;\/?:@&=+\$,()<>% '"\x00-\x1f\x7f-\xff])/sprintf "%%%02X", ord $1/ge;
   $str
}

sub escape_attr($) {
   my $str = shift;
   utf8::upgrade $str; # TODO: remove?
   $str =~ s/(['<>&\x00-\x1f\x80-\x9f])/sprintf "&#%d;", ord $1/ge;
   "'$str'"
}

my @MON  = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my @WDAY = qw/Sun Mon Tue Wed Thu Fri Sat/;

# format can be 'http' (defaut) or 'cookie'
sub unixtime2http {
   my($time, $format) = @_;

   my $sc = $format eq "cookie" ? '-' : ' ';

   my ($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime $time;

   sprintf "%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
           $WDAY[$wday], $mday, $MON[$mon], $year+1900,
           $hour, $min, $sec;
}

=item errbox $error, $explanation [DEPRECATED]

Render a two-part error-box, very distinctive, very ugly, very visible!

=cut

sub errbox {
   "<table border=\"5\" width=\"100%\" cellpadding=\"10mm\">"
   ."<tr><td bgcolor=\"#ff0000\"><font color=\"#000000\" size=\"+2\"><b>$_[0]</b></font></td></tr>"
   ."<tr><td bgcolor=\"#c0c0ff\"><font color=\"#000000\" size=\"+1\"><b><pre>$_[1]</pre></b>&#160;</font></td></tr>"
   ."</table>";
}

=back

=head2 Convenience Functions to Create XHTML Elements

The following functions are shortcuts to various often-used html tags
(mostly form elements). All of them allow an initial 
argument C<attrs> of type hashref which can contain attribute => value
pairs. Attributes always required for the given element (e.g.
"name" for form-elements) can usually be specified directly without using
that hash. C<$value> is usually the initial state/content of the
input element (e.g. some text for C<textfield> or boolean for C<checkbox>).

=over 4

=item tag $tagname [, \%attr ] [, $content...]

Return an XHTML element with the given tagname, optional attributes
and content. C<img>, C<br> and C<input> elements are handled specially
(content model empty).

=cut

my %html_empty = (
   img   => 1, IMG   => 1, Img   => 1,
   br    => 1, BR    => 1, Br    => 1,
   input => 1, INPUT => 1, Input => 1,
);

sub tag {
   my $tag = shift;
   my $r = "<$tag";
   if (ref $_[0] eq "HASH") {
      my $attr = shift;
      while (my ($k, $v) = each %$attr) {
         $r .= " $k=" . escape_attr($v);
      }
   }
   if (@_ or !$html_empty{$tag}) {
      $r .= ">";
      $r .= (join "", @_)."</$tag>" if @_;
   } else {
      $r .= " />"; # space for compatibility
   }
   $r;
}

*xmltag = \&tag; # DEPRECATED / NYI

=item $ahref = alink [\%attrs,] contents, url [DEPRECATED]

Create "a link" (a href) with the given contents, pointing at the given
url. It uses single quotes to delimit the url, so watch out and escape
yourself!

=cut

# "link content, url"
sub alink {
   tag a => { ref $_[0] eq "HASH" ? %{+shift} : (), href => $_[1] }, $_[0]
}

=item submit [\%attrs,] $name [, $value]

=item submit_image [\%attrs,] $name, $img_url [, $value]

Submits a graphical submit button. C<$img_url> must be the url to the image that is to be used.

=item reset_button [\%attrs,] $name 

=item textfield [\%attrs,] $name [, $value]

Creates an input element of type text named C<$name>. Examples:

   textfield "field1";
   textfield "field1", "some text";
   textfield { maxlength => 20 }, "field1";

=item textarea [\%attrs,] $name, [, $value]

Creates an input element of type textarea named C<$name>

=item password_field [\%attrs,] $name [, $value]

Creates an input element of type password named C<$name>

=item hidden [\%attrs,] $name [, $value]

Creates an input element of type hidden named C<$name>

=item checkbox [\%attrs,] $name [, $value [, $checked]]

Creates an input element of type checkbox named C<$name>

=item radio [\%attrs,] $name [, $value [, $checked]]

Creates an input element of type radiobutton named C<$name>

=item filefield [\%attrs,] $name [, $value]

Creates an input element of type file named C<$name>

=cut

sub submit		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift || "", type => 'submit' } }
sub submit_image	{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, src => shift, value => shift || "", type => 'image' } }
sub reset_button	{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, type => 'reset' } }
sub password_field	{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, type => 'password' } }
sub textfield		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, type => 'text'     } }
sub button		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, type => 'button'   } }
sub hidden		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, type => 'hidden'   } }
sub checkbox		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, (shift) ? (checked => "checked") : (), type => 'checkbox' } }
sub radio		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, (shift) ? (checked => "checked") : (), type => 'radio'    } }
sub filefield		{ tag "input", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift, value => shift, type => 'file'     } }

sub textarea		{ tag "textarea", { ref $_[0] eq "HASH" ? %{+shift} : (), name => shift },
                                          ($PApp::content_type eq "application/xhtml+xml" ? "" : "\n"), @_ }

=item selectbox [\%attrs,] $name, [$selected, [, $key => $text...]]

Creates an input element of type select(box) named C<$name>. C<$selected>
should be the currently selected value (or an arrayref containing all
selected values). All remaining arguments are treated as name (displayed)
=> value (submitted) pairs.

=cut

sub selectbox {
   my $attrs = ref $_[0] eq "HASH" ? shift : {};
   my $name = shift;
   my %selected;
   if (ref $_[0]) {
      @selected{@{+shift}}++;
   } else {
      $selected{+shift}++;
   }
   my $contents;
   while (@_) {
      my $key = shift;
      my $val = shift;
      $contents .= tag "option",
                       { value => $key,
                         exists $selected{$key} ? (selected => "selected") : ()
                       },
                       $val;
   }
   tag "select", { name => $name, %$attrs }, $contents;
}

=item javascript $code

Returns a script element containing correctly quoted code inside a comment
as recommended in HTML 4. Every occurence of C<--> will be replaced by
C<-\-> to avoid generating illegal syntax (for XHTML compatibility). Yes,
this means that the decrement operator is certainly out. One would expect
browsers to properly support entities inside script tags, but of course
they don't, ruling better solutions totally out.

If you use a stylesheet, consider something like this for your head-section:

   <script type="text/javascript" language="javascript1.3" defer="defer">
      <xsl:comment>
         <xsl:text>&#10;</xsl:text>
         <xsl:for-each select="descendant::script">
            <xsl:text disable-output-escaping="yes"><xsl:value-of select="text()"/></xsl:text>
         </xsl:for-each>
         <xsl:text>//</xsl:text>
      </xsl:comment>
   </script>

=cut

sub javascript($) {
   my $code = shift;
   $code =~ s/--/-\\-/g;
   "<script type='text/javascript'><!--\n$code\n// --></script>";
}

=item mailto_url $mailaddr, key => value, ...

Create a mailto url with the specified headers (see RFC 2368). All values
will be properly escaped for you. Example:

 mailto_url "schmorp\@schmorp.de",
            subject => "Mail from me",
            body => "hello, world!";

=cut

sub mailto_url {
   my $url = "mailto:".shift;
   if (@_) {
      $url .= "?";
      for(;;) {
         my $key = shift;
         my $val = shift;
         $val = PApp::Util::mime_header $val unless $key =~ /^body$/i;
         $url .= $key . "=" . escape_uri $val;
         last unless @_;
         $url .= "&amp;";
      }
   }
   $url;
}

sub unescape($) {
   local $_ = $_[0];
   y/+/ /;
   s/%([0-9a-fA-F][0-9a-fA-F])/chr hex $1/ge;
   $_;
}

# parse application/x-www-form-urlencoded
sub parse_params($) {
   map { /([^=]+)(?:=(.*))?/ and (unescape $1, unescape $2) } split /[&;]/, $_[0];
}

=back

=head1 SEE ALSO

L<PApp>, L<PApp::XML>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

