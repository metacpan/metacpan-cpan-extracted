#!/usr/bin/perl -w

# t/html.t - check output from Pod::PseudoPod::HTML

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 31;

use_ok('Pod::PseudoPod::HTML') or exit;

my $parser = Pod::PseudoPod::HTML->new ();
isa_ok ($parser, 'Pod::PseudoPod::HTML');

my $results;

initialize($parser, $results);
$parser->parse_string_document( "=head0 Narf!" );
is($results, "<h1>Narf!</h1>\n\n", "head0 level output");

initialize($parser, $results);
$parser->parse_string_document( "=head1 Poit!" );
is($results, "<h2>Poit!</h2>\n\n", "head1 level output");

initialize($parser, $results);
$parser->parse_string_document( "=head2 I think so Brain." );
is($results, "<h3>I think so Brain.</h3>\n\n", "head2 level output");

initialize($parser, $results);
$parser->parse_string_document( "=head3 I say, Brain..." );
is($results, "<h4>I say, Brain...</h4>\n\n", "head3 level output");

initialize($parser, $results);
$parser->parse_string_document( "=head4 Zort!" );
is($results, "<h5>Zort!</h5>\n\n", "head4 level output");


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

Gee, Brain, what do you want to do tonight?
EOPOD

is($results, <<'EOHTML', "simple paragraph");
<p>Gee, Brain, what do you want to do tonight?</p>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

B: Now, Pinky, if by any chance you are captured during this mission,
remember you are Gunther Heindriksen from Appenzell. You moved to
Grindelwald to drive the cog train to Murren. Can you repeat that?

P: Mmmm, no, Brain, don't think I can.
EOPOD

is($results, <<'EOHTML', "multiple paragraphs");
<p>B: Now, Pinky, if by any chance you are captured during this mission,
remember you are Gunther Heindriksen from Appenzell. You moved to
Grindelwald to drive the cog train to Murren. Can you repeat that?</p>

<p>P: Mmmm, no, Brain, don't think I can.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item *

P: Gee, Brain, what do you want to do tonight?

=item *

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EOHTML', "simple bulleted list");
<ul>

<li>P: Gee, Brain, what do you want to do tonight?</li>

<li>B: The same thing we do every night, Pinky. Try to take over the
world!</li>

</ul>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item 1

P: Gee, Brain, what do you want to do tonight?

=item 2

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EOHTML', "numbered list");
<ol>

<li>1. P: Gee, Brain, what do you want to do tonight?</li>

<li>2. B: The same thing we do every night, Pinky. Try to take over the
world!</li>

</ol>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=over

=item Pinky

Gee, Brain, what do you want to do tonight?

=item Brain

The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($results, <<'EOHTML', "list with text headings");
<ul>

<li>Pinky

<p>Gee, Brain, what do you want to do tonight?</p>

<li>Brain

<p>The same thing we do every night, Pinky. Try to take over the world!</p>

</ul>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

  1 + 1 = 2;
  2 + 2 = 4;

EOPOD

is($results, <<'EOHTML', "code block");
<pre><code>  1 + 1 = 2;
  2 + 2 = 4;</code></pre>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a C<functionname>.
EOPOD
is($results, <<"EOHTML", "code entity in a paragraph");
<p>A plain paragraph with a <code>functionname</code>.</p>

EOHTML


initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with aN<footnote entry>.
EOPOD
is($results, <<"EOHTML", "footnote entity in a paragraph");
<p>A plain paragraph with a (footnote: footnote entry).</p>

EOHTML


initialize($parser, $results);
$parser->add_body_tags(1);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with body tags turned on.
EOPOD
is($results, <<"EOHTML", "adding html body tags");
<html>
<body>

<p>A plain paragraph with body tags turned on.</p>

</body>
</html>

EOHTML


initialize($parser, $results);
$parser->add_body_tags(1);
$parser->add_css_tags(1);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with body tags and css tags turned on.
EOPOD
is($results, <<"EOHTML", "adding html body tags and css tags");
<html>
<body>
<link rel='stylesheet' href='style.css' type='text/css'>

<p>A plain paragraph with body tags and css tags turned on.</p>

</body>
</html>

EOHTML


initialize($parser, $results);
$parser->add_css_tags(1);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with aN<footnote entry> and css tags.
EOPOD
is($results, <<"EOHTML", "css footnote entity in a paragraph");
<p>A plain paragraph with a<font class="footnote"> (footnote: footnote
entry)</font> and css tags.</p>

EOHTML


initialize($parser, $results);
$parser->add_css_tags(1);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a U<http://test.url.com/stuff/and/junk.txt>.
EOPOD
is($results, <<"EOHTML", "URL entity in a paragraph");
<p>A plain paragraph with a <font
class="url">http://test.url.com/stuff/and/junk.txt</font>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a Z<crossreferenceendpoint>.
EOPOD
is($results, <<"EOHTML", "Link anchor entity in a paragraph");
<p>A plain paragraph with a <a name="crossreferenceendpoint">.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a A<crossreferencelink>.
EOPOD
is($results, <<"EOHTML", "Link entity in a paragraph");
<p>A plain paragraph with a <a href="#crossreferencelink">link</a>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a G<superscript>.
EOPOD
is($results, <<"EOHTML", "Superscript in a paragraph");
<p>A plain paragraph with a <sup>superscript</sup>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a H<subscript>.
EOPOD
is($results, <<"EOHTML", "Subscript in a paragraph");
<p>A plain paragraph with a <sub>subscript</sub>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with B<bold text>.
EOPOD
is($results, <<"EOHTML", "Bold text in a paragraph");
<p>A plain paragraph with <b>bold text</b>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with I<italic text>.
EOPOD
is($results, <<"EOHTML", "Italic text in a paragraph");
<p>A plain paragraph with <i>italic text</i>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with R<replaceable text>.
EOPOD
is($results, <<"EOHTML", "Replaceable text in a paragraph");
<p>A plain paragraph with <em>replaceable text</em>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

A plain paragraph with a F<filename>.
EOPOD
is($results, <<"EOHTML", "File name in a paragraph");
<p>A plain paragraph with a <i>filename</i>.</p>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=pod

  # this header is very important & don't you forget it
  my $text = "File is: " . <FILE>;
EOPOD
like($results, qr/&quot;/, "Verbatim text with encodable quotes");
like($results, qr/&amp;/, "Verbatim text with encodable ampersands");
like($results, qr/&lt;/, "Verbatim text with encodable less-than");
like($results, qr/&gt;/, "Verbatim text with encodable greater-than");

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
