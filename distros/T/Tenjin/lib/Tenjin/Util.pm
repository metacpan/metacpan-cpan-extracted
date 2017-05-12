package Tenjin::Util;

use strict;
use warnings;
use HTML::Entities;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

=head1 NAME

Tenjin::Util - Utility methods for Tenjin.

=head1 SYNOPSIS

	# in your templates:

	# encode a URL
	[== encode_url('http://www.google.com/search?q=tenjin&ie=utf-8&oe=utf-8&aq=t') =]
	# returns http%3A//www.google.com/search%3Fq%3Dtenjin%26ie%3Dutf-8%26oe%3Dutf-8%26aq%3Dt

	# escape a string of lines of HTML code
	<?pl	my $string = '<h1>You & Me</h1>\n<h2>Me & You</h2>'; ?>
	[== text2html($string) =]
	# returns &lt;h1&gt;You &amp; Me&lt;/h1&gt;<br />\n&lt;h2&gt;Me &amp; You&lt;/h2&gt;

=head1 DESCRIPTION

This module provides a few utility functions which can be used in your
templates for your convenience. These include functions to (un)escape
and (en/de)code URLs.

=head1 METHODS

=head2 expand_tabs( $str, [$tabwidth] )

Receives a string that might contain tabs in it, and replaces those
tabs with spaces, each tab with the number of spaces defined by C<$tabwidth>,
or, if C<$tabwidth> was not passed, with 8 spaces.

=cut

sub expand_tabs {
	my ($str, $tabwidth) = @_;

	$tabwidth ||= 8;
	my $s = '';
	my $pos = 0;
	while ($str =~ /.*?\t/sg) { # /(.*?)\t/ may be slow
		my $end = $+[0];
		my $text = substr($str, $pos, $end - 1 - $pos);
		my $n = rindex($text, "\n");
		my $col = $n >= 0 ? length($text) - $n - 1 : length($text);
		$s .= $text;
		$s .= ' ' x ($tabwidth - $col % $tabwidth);
		$pos = $end;
	}
	my $rest = substr($str, $pos);
	return $s;
}

=head2 escape_xml( $str )

Receives a string of XML (or (x)HTML) code and converts the characters
<>&\' to HTML entities. This is the method that is invoked when you use
[= $expression =] in your templates.

=cut

sub escape_xml {
	encode_entities($_[0], '<>&"\'');
}

=head2 unescape_xml( $str )

Receives a string of escaped XML (or (x)HTML) code (for example, a string
that was escaped with the L<escape_xml()|escape_xml( $str )> function,
and 'unescapes' all HTML entities back to their actual characters.

=cut

sub unescape_xml {
	decode_entities($_[0]);
}

=head2 encode_url( $url )

Receives a URL and encodes it by escaping 'non-standard' characters.

=cut

sub encode_url {
	my $url = shift;

	$url =~ s/([^-A-Za-z0-9_.\/])/sprintf("%%%02X", ord($1))/sge;
	$url =~ tr/ /+/;
	return $url;
}

=head2 decode_url( $url )

Does the opposite of L<encode_url()|encode_url( $url )>.

=cut

sub decode_url {
	my $url = shift;

	$url =~ s/\%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/sge;
	return $url;
}

=head2 checked( $val )

Receives a value of some sort, and if it is a true value, returns the string
' checked="checked"' which can be appended to HTML checkboxes.

=cut

sub checked {
	$_[0] ? ' checked="checked"' : '';
}

=head2 selected( $val )

Receives a value of some sort, and if it is a true value, returns the string
' selected="selected"' which can be used in an option in an HTML select box.

=cut

sub selected {
	$_[0] ? ' selected="selected"' : '';
}

=head2 disabled( $val )

Receives a value of some sort, and if it is a true value, returns the string
' disabled="disabled"' which can be used in an HTML input.

=cut

sub disabled {
	$_[0] ? ' disabled="disabled"' : '';
}

=head2 nl2br( $text )

Receives a string of text containing lines delimited by newline characters
(\n, or possibly \r\n) and appends an HTML line break (<br />) to every
line (the newline character is left untouched).

=cut

sub nl2br {
	my $text = shift;

	$text =~ s/(\r?\n)/<br \/>$1/g;
	return $text;
}

=head2 text2html( $text )

Receives a string of text containing lines delimited by newline characters,
and possibly some XML (or (x)HTML) code, escapes that code with
L<escape_xml()|escape_xml( $str )> and then appends an HTML line break
to every line with L<nl2br()|nl2br( $text )>.

=cut

sub text2html {
	nl2br(escape_xml($_[0]));
}

=head2 tagattr( $name, $expr, [$value] )

=cut

sub tagattr {
	my ($name, $expr, $value) = @_;

	return '' unless $expr;
	$value = $expr unless defined $value;
	return " $name=\"$value\"";
}

=head2 tagattrs( %attrs )

=cut

sub tagattrs {
	my (%attrs) = @_;

	my $s = '';
	while (my ($k, $v) = each %attrs) {
		$s .= " $k=\"".escape_xml($v)."\"" if defined $v;
	}
	return $s;
}

=head2 new_cycle( @items )

Creates a subroutine reference that can be used for cycling through the
items of the C<@items> array. So, for example, you can:

	my $cycle = new_cycle(qw/red green blue/);
	print $cycle->(); # prints 'red'
	print $cycle->(); # prints 'green'
	print $cycle->(); # prints 'blue'
	print $cycle->(); # prints 'red' again

=cut

sub new_cycle {
	my $i = 0;
	sub { $_[$i++ % scalar @_] };  # returns
}

=head1 INTERNAL(?) METHODS

=head2 _p( $expression )

Wraps a Perl expression in a customized wrapper which will be processed
by the Tenjin preprocessor and replaced with the standard [== $expression =].

=cut

sub _p {
	"<`\#$_[0]\#`>";
}

=head2 _P( $expression )

Wrap a Perl expression in a customized wrapper which will be processed
by the Tenjin preprocessor and replaced with the standard [= $expression =],
which means the expression will be escaped.

=cut

sub _P {
	"<`\$$_[0]\$`>";
}

=head2 _decode_params( $s )

=cut

sub _decode_params {
	my $s = shift;

	return '' unless $s;

	$s =~ s/%3C%60%23(.*?)%23%60%3E/'[=='.decode_url($1).'=]'/ge;
	$s =~ s/%3C%60%24(.*?)%24%60%3E/'[='.decode_url($1).'=]'/ge;
	$s =~ s/&lt;`\#(.*?)\#`&gt;/'[=='.unescape_xml($1).'=]'/ge;
	$s =~ s/&lt;`\$(.*?)\$`&gt;/'[='.unescape_xml($1).'=]'/ge;
	$s =~ s/<`\#(.*?)\#`>/[==$1=]/g;
	$s =~ s/<`\$(.*?)\$`>/[=$1=]/g;

	return $s;
}

1;

=head1 SEE ALSO

L<Tenjin>, L<Tenjin::Template>, L<Tenjin::Context>.

=head1 AUTHOR, LICENSE AND COPYRIGHT

See L<Tenjin>.

=cut
