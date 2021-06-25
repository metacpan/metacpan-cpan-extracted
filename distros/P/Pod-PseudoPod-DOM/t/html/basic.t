use strict;
use warnings;

use Test::More;
use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use_ok('Pod::PseudoPod::DOM') or exit;

my $parser = Pod::PseudoPod::DOM->new(
    formatter_role => 'Pod::PseudoPod::DOM::Role::HTML'
);
isa_ok $parser, 'Pod::PseudoPod::DOM';

my $result = parse( "=head0 Narf!" );
my $link   = encode_link( 'Narf!' );
like $result, qr|<h1 id="$link">Narf!</h1>\n\n|,
    "head0 level output";

$result = parse( "=head1 Poit!" );
$link   = encode_link( 'Poit!' );
like $result, qr|<h2 id="$link">Poit!</h2>\n\n|,
    "head1 level output";

$result = parse( "=head2 I think so Brain." );
$link   = encode_link( 'IthinksoBrain.' );
like $result,
    qr|<h3 id="$link">I think so Brain.</h3>\n\n|,
     "head2 level output";

$result = parse( "=head3 I say, Brain..." );
$link   = encode_link( 'Isay,Brain...' );
like $result, qr|<h4 id="$link">I say, Brain...</h4>\n|,
    "head3 level output";

$result = parse( "=head4 Zort!" );
$link   = encode_link( 'Zort!' );
like $result, qr|<h5 id="$link">Zort!</h5>\n\n|,
    "head4 level output";

$result = parse( <<'EOPOD' );
=pod

Gee, Brain, what do you want to do tonight?
EOPOD

is $result, <<'EOHTML', "simple paragraph";
<p>Gee, Brain, what do you want to do tonight?</p>

EOHTML


$result = parse( <<'EOPOD' );
=pod

B: Now, Pinky, if by any chance you are captured during this mission,
remember you are Gunther Heindriksen from Appenzell. You moved to
Grindelwald to drive the cog train to Murren. Can you repeat that?

P: Mmmm, no, Brain, don't think I can.
EOPOD

my $html =
  '<p>B: Now, Pinky, if by any chance you are captured during this mission, '
. 'remember you are Gunther Heindriksen from Appenzell. You moved to '
. "Grindelwald to drive the cog train to Murren. Can you repeat that?</p>\n\n"
. "<p>P: Mmmm, no, Brain, don&#39;t think I can.</p>\n\n";

is $result, $html, "multiple paragraphs";

$result = parse( <<'EOPOD' );
=over

=item *

P: Gee, Brain, what do you want to do tonight?

=item *

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is $result, <<'EOHTML', "simple bulleted list";
<ul>

<li>P: Gee, Brain, what do you want to do tonight?</li>

<li>B: The same thing we do every night, Pinky. Try to take over the world!</li>

</ul>

EOHTML


$result = parse( <<'EOPOD' );
=over

=item 1

P: Gee, Brain, what do you want to do tonight?

=item 2

B: The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is $result, <<'EOHTML', "numbered list";
<ol>

<li number="1">P: Gee, Brain, what do you want to do tonight?</li>

<li number="2">B: The same thing we do every night, Pinky. Try to take over the world!</li>

</ol>

EOHTML


$result = parse( <<'EOPOD' );
=over

=item Pinky

Gee, Brain, what do you want to do tonight?

=item Brain

The same thing we do every night, Pinky. Try to take over the world!

=back

EOPOD

is($result, <<'EOHTML', "list with text headings");
<ul>

<li><p>Pinky</p>

<p>Gee, Brain, what do you want to do tonight?</p>

</li>

<li><p>Brain</p>

<p>The same thing we do every night, Pinky. Try to take over the world!</p>

</li>

</ul>

EOHTML


$result = parse( <<'EOPOD' );
=pod

  1 + 1 = 2;
  2 + 2 = 4;

EOPOD

is $result, <<'EOHTML', "code block";
<pre><code>  1 + 1 = 2;
  2 + 2 = 4;</code></pre>

EOHTML

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a C<functionname>.
EOPOD
is($result, <<"EOHTML", "code entity in a paragraph");
<p>A plain paragraph with a <code>functionname</code>.</p>

EOHTML


$result = parse( <<'EOPOD' );
=pod

A plain paragraph with aN<footnote entry>.
EOPOD
is($result, <<"EOHTML", "footnote entity in a paragraph");
<p>A plain paragraph with a <span class="footnote">footnote entry</span>.</p>

EOHTML


$result = parse( <<'EOPOD', formatter_args => { add_body_tags => 1 } );
=pod

A plain paragraph with body tags turned on.
EOPOD
is $result, <<"EOHTML", "adding html body tags";
<!DOCTYPE html>
<html lang="en">
<head>
<link rel="stylesheet" href="../css/style.css" type="text/css" />
</head>
<body>

<p>A plain paragraph with body tags turned on.</p>

</body>
</html>
EOHTML

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a U<http://test.url.com/stuff/and/junk.txt>.
EOPOD

$html = '<p>A plain paragraph with a <a class="url" '
      . 'href="http://test.url.com/stuff/and/junk.txt">'
      . "http://test.url.com/stuff/and/junk.txt</a>.</p>\n\n";

is $result, $html, "URL entity in a paragraph";

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a Z<crossreferenceendpoint>.
EOPOD

$link = encode_link( 'crossreferenceendpoint' );
is $result, <<"EOHTML", 'Link anchor entity in a paragraph';
<p>A plain paragraph with a <a name="$link"></a>.</p>

EOHTML

$result = parse_with_anchors( <<'EOPOD' );
=pod

=head1 XREF header

Z<crossreferencelink>

=head2 No XREF Header

A plain paragraph with a A<crossreferencelink>.
EOPOD

$link = encode_link( 'crossreferencelink' );
like $result,
     qr!paragraph with a <a href="basic.t.pod#$link">XREF header</a>!,
    'Link entity in a paragraph';

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a G<superscript>.
EOPOD
is($result, <<"EOHTML", "Superscript in a paragraph");
<p>A plain paragraph with a <sup>superscript</sup>.</p>

EOHTML

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a H<subscript>.
EOPOD
is($result, <<"EOHTML", "Subscript in a paragraph");
<p>A plain paragraph with a <sub>subscript</sub>.</p>

EOHTML
$result = parse( <<'EOPOD' );
=pod

A plain paragraph with B<bold text>.
EOPOD
is($result, <<"EOHTML", "Bold text in a paragraph");
<p>A plain paragraph with <strong>bold text</strong>.</p>

EOHTML

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with I<italic text>.
EOPOD
is($result, <<"EOHTML", "Italic text in a paragraph");
<p>A plain paragraph with <em>italic text</em>.</p>

EOHTML
$result = parse( <<'EOPOD' );
=pod

A plain paragraph with R<replaceable text>.
EOPOD
is($result, <<"EOHTML", "Replaceable text in a paragraph");
<p>A plain paragraph with <em>replaceable text</em>.</p>

EOHTML

$result = parse( <<'EOPOD' );
=pod

A plain paragraph with a F<filename>.
EOPOD
is($result, <<"EOHTML", "File name in a paragraph");
<p>A plain paragraph with a <em>filename</em>.</p>

EOHTML

$result = parse( <<'EOPOD' );
=pod

  # this header is very important & don't you forget it
  my $text = "File is: " . <FILE>;
EOPOD

like $result, qr/&quot;/, "Verbatim text with encodable quotes";
like $result, qr/&amp;/,  "Verbatim text with encodable ampersands";
like $result, qr/&lt;/,   "Verbatim text with encodable less-than";
like $result, qr/&gt;/,   "Verbatim text with encodable greater-than";
like $result, qr/&quot;File is: &quot; . &lt;FILE&gt;/,
    '... encoding everything correctly';

$result = parse( <<'EOPOD' );
=begin programlisting

    This verbatim text has B<bold> & I<emphasized> text.

=end programlisting
EOPOD

like $result, qr!<code>\s*This verbatim text has <strong>bold</strong>!,
    '... verbatim should not encode B<> tags';

like $result, qr!&amp; <em>emphasized</em> text.!,
    '... nor I<> tags';

done_testing;
