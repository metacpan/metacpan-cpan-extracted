#!/usr/bin/perl -w

# t/docbook.t - check output from Pod::PseudoPod::DocBook

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 27;

use_ok('Pod::PseudoPod::DocBook') or exit;

my $parser = Pod::PseudoPod::DocBook->new ();
isa_ok ($parser, 'Pod::PseudoPod::DocBook');

my $results;

initialize($parser, $results);
$parser->chapter_num(5);
$parser->parse_string_document( <<'EOPOD' );
=head0 Narf!

=head1 Poit!

=head2 I think so Brain.

=head3 I say, Brain...

=head3 What do you want to do tonight, Brain?

=head4 Zort!

=head1 Egads!
EOPOD

is($results, <<'EODB', "multiple head level output");
<chapter id="CHP-5">
<title>Narf!</title>
<sect1 id="CHP-5-SECT-1">
<title>Poit!</title>
<sect2 id="CHP-5-SECT-1.1">
<title>I think so Brain.</title>
<sect3 id="CHP-5-SECT-1.1.1">
<title>I say, Brain...</title>
</sect3>
<sect3 id="CHP-5-SECT-1.1.2">
<title>What do you want to do tonight, Brain?</title>
<sect4 id="CHP-5-SECT-1.1.2.1">
<title>Zort!</title>
</sect4>
</sect3>
</sect2>
</sect1>
<sect1 id="CHP-5-SECT-2">
<title>Egads!</title>
</sect1>
</chapter>

EODB

initialize($parser, $results);
$parser->chapter_type('preface');
$parser->parse_string_document( <<'EOPOD' );
=head0 Narf!

=head1 Poit!
EOPOD

is($results, <<'EODB', "multiple head level output (preface chapter)");
<preface id="PREFACE">
<title>Narf!</title>
<sect1 id="PREFACE-SECT-1">
<title>Poit!</title>
</sect1>
</preface>

EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Gee, Brain, what do you want to do tonight?
EOPOD

is($results, <<'EODB', "simple paragraph");
<para>Gee, Brain, what do you want to do tonight?</para>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

B: Now, Pinky, if by any chance you are captured during this mission,
remember you are Gunther Heindriksen from Appenzell. You moved to
Grindelwald to drive the cog train to Murren. Can you repeat that?

P: Mmmm, no, Brain, don't think I can.
EOPOD

is($results, <<'EODB', "multiple paragraphs");
<para>B: Now, Pinky, if by any chance you are captured during this mission, remember you are Gunther Heindriksen from Appenzell. You moved to Grindelwald to drive the cog train to Murren. Can you repeat that?</para>
<para>P: Mmmm, no, Brain, don&#39;t think I can.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item *

P: Gee, Brain, what do you want to do tonight?

=item *

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EODB', "simple bulleted list");
<itemizedlist>
<listitem><para>P: Gee, Brain, what do you want to do tonight?</para></listitem>
<listitem><para>B: The same thing we do every night, Pinky. Try to take over the world!</para></listitem>
</itemizedlist>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item 1

P: Gee, Brain, what do you want to do tonight?

=item 2

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EODB', "numbered list");
<orderedlist>
<listitem><para>P: Gee, Brain, what do you want to do tonight?
</para></listitem>
<listitem><para>B: The same thing we do every night, Pinky. Try to take over the world!
</para></listitem>
</orderedlist>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item Pinky

Gee, Brain, what do you want to do tonight?

=item Brain

The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EODB', "list with text headings");
<variablelist>
<varlistentry>
<term>Pinky</term>
<listitem>
<para>Gee, Brain, what do you want to do tonight?</para>
</listitem>
</varlistentry>
<varlistentry>
<term>Brain</term>
<listitem>
<para>The same thing we do every night, Pinky. Try to take over the world!</para>
</listitem>
</varlistentry>
</variablelist>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

  1 + 1 = 2;
  2 + 2 = 4;

EOPOD

is($results, <<'EODB', "code block");
<programlisting>
  1 + 1 = 2;
  2 + 2 = 4;
</programlisting>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a C<functionname>.
EOPOD
is($results, <<"EODB", "code entity in a paragraph");
<para>A plain paragraph with a <literal>functionname</literal>.</para>
EODB


initialize($parser, $results);
$parser->chapter_num(9);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a footnote.N<And the footnote is...>
EOPOD
is($results, <<"EODB", "footnote entity in a paragraph");
<para>A plain paragraph with a footnote.<footnote id="CHP-9-FNOTE-1" label="*"><para>And the footnote is...</para></footnote></para>
EODB

initialize($parser, $results);
$parser->chapter_type('preface');
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a footnote.N<And the footnote is...>
EOPOD
is($results, <<"EODB", "footnote entity in a paragraph (preface chapter)");
<para>A plain paragraph with a footnote.<footnote id="PREFACE-FNOTE-1" label="*"><para>And the footnote is...</para></footnote></para>
EODB


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a U<http://test.url.com/stuff/and/junk.txt>.
EOPOD
is($results, <<"EODB", "URL entity in a paragraph");
<para>A plain paragraph with a <ulink url="http://test.url.com/stuff/and/junk.txt"/>.</para>
EODB

TODO: {
      local $TODO = "waiting for spec from O'Reilly";
initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a Z<crossreferenceendpoint>.
EOPOD
is($results, <<"EODB", "Link anchor entity in a paragraph");
<para>A plain paragraph with a <a name="crossreferenceendpoint">.</para>
EODB
};

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a A<crossreferencelink>.
EOPOD
is($results, <<"EODB", "Link entity in a paragraph");
<para>A plain paragraph with a <xref linkend="crossreferencelink"/>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a G<superscript>.
EOPOD
is($results, <<"EODB", "Superscript in a paragraph");
<para>A plain paragraph with a <superscript>superscript</superscript>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a H<subscript>.
EOPOD
is($results, <<"EODB", "Subscript in a paragraph");
<para>A plain paragraph with a <subscript>subscript</subscript>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with B<bold text>.
EOPOD
is($results, <<"EODB", "Bold text in a paragraph");
<para>A plain paragraph with <emphasis role="strong">bold text</emphasis>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with I<italic text>.
EOPOD
is($results, <<"EODB", "Italic text in a paragraph");
<para>A plain paragraph with <emphasis>italic text</emphasis>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with R<replaceable text>.
EOPOD
is($results, <<"EODB", "Replaceable text in a paragraph");
<para>A plain paragraph with <replaceable>replaceable text</replaceable>.</para>
EODB

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a F<filename>.
EOPOD
is($results, <<"EODB", "File name in a paragraph");
<para>A plain paragraph with a <filename>filename</filename>.</para>
EODB

TODO: {
      local $TODO = "waiting for spec from O'Reilly";
initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin author

A paragraph inside a block.

=end author
EOPOD
is($results, <<"EODB", "File name in a paragraph");
<author>
<para>A paragraph inside a block.</para>
</author>
EODB

};

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

  # this header is very important & don't you forget it
  B<my $file = <FILEE<gt> || 'Blank!';>
  my $text = "File is: " . <FILE>;
EOPOD
like($results, qr/&quot;/, "Verbatim text with encodable quotes");
like($results, qr/&amp;/, "Verbatim text with encodable ampersands");
like($results, qr/&lt;/, "Verbatim text with encodable less-than");
like($results, qr/&gt;/, "Verbatim text with encodable greater-than");

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::DocBook->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
