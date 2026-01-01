#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

#my $pdf = PDF::Builder->new();
my $pdf = PDF::Builder->new('compress'=>'none');
my $content;
my ($page, $text, $grfx);

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory

my $magenta = '#ff00ff';
my $fs = 15;
my ($rc, $next_y, $unused);

print "======================================================= pg 1\n";
print "---- A variety of lists\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Unordered (bulleted) lists with various markers</h2>
<h3>Nested list <i>is</i> within &lt;li&gt; of parent</h3>
<ul> <!-- default disc -->
  <li>Unordered 1A, disc and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.</li>
  <li>Unordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, circle</li>
    <li>Unordered 2B and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.
    <ul> <!-- default (filled) square -->
      <li>Unordered 3A, square</li>
      <li>Unordered 3B
      <ul style="list-style-type: box"> <!-- box (open square) -->
        <li>Unordered 4A, box. A &ldquo;box&rdquo; marker is non-standard &mdash; it is an empty square marker. A bit more filler here. How about a <i>lot</i> more, driving it to three lines in all? Oh yeah, that's the ticket!</li>
        <li>Unordered 4B
        <ul> <!-- and back to disc -->
          <li>Unordered 5A, default disc</li>
          <li>Unordered 5B</li>
	</ul>
	<ul style="list-style-type: square">
          <li>Unordered 6A, square</li>
          <li>Unordered 6B</li>
	</ul></li> <!-- end li 4B -->
      </ul></li> <!-- end li 3B -->
    </ul></li> <!-- end li 2A -->
  </ul></li> <!-- end li 1B -->
</ul>

<h3>Nested list is <i>not</i> within &lt;li&gt; of parent</h3>
<ul> <!-- default disc -->
  <li>Unordered 1A, disc and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.</li>
  <li>Unordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, circle</li>
    <li>Unordered 2B and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.</li>
    <ul> <!-- default (filled) square -->
      <li>Unordered 3A, square</li>
      <li>Unordered 3B</li>
      <ul style="list-style-type: box"> <!-- box (open square) -->
        <li>Unordered 4A, box. A &ldquo;box&rdquo; marker is non-standard &mdash; it is an empty square marker. A bit more filler here. How about a <i>lot</i> more, driving it to three lines in all? Oh yeah, that's the ticket!</li>
        <li>Unordered 4B</li>
        <ul>
          <li>Unordered 5A, default disc</li>
          <li>Unordered 5B</li>
	</ul>
	<ul style="list-style-type: square">
          <li>Unordered 6A, square</li>
          <li>Unordered 6B</li>
	</ul>
      </ul>
    </ul>
  </ul>
</ul>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

print "======================================================= pg 2\n";
print "---- More list examples\n";

$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

# if you are using <ul> or <ol> with single digit numbers, it should be safe
# to reduce marker_width and marker_gap
$content = <<"END_OF_CONTENT";
<h3>Nested list with narrower marker widths and gaps</h3>
<ul> <!-- default disc -->
  <li>Unordered 1A, disc and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.</li>
  <li>Unordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, circle</li>
    <li>Unordered 2B and here is a bunch more text to try to cause a spill to a second line. Looks like we need a bit more filler here.
    <ul> <!-- default (filled) square -->
      <li>Unordered 3A, square</li>
      <li>Unordered 3B
      <ul style="list-style-type: box"> <!-- box (open square) -->
        <li>Unordered 4A, box. A &ldquo;box&rdquo; marker is non-standard &mdash; it is an empty square marker. A bit more filler here. How about a <i>lot</i> more, driving it to three lines in all? Oh yeah, that's the ticket!</li>
        <li>Unordered 4B
        <ul> <!-- and back to disc -->
          <li>Unordered 5A, default disc</li>
          <li>Unordered 5B</li>
	</ul>
	<ul style="list-style-type: square">
          <li>Unordered 6A, square</li>
          <li>Unordered 6B</li>
	</ul></li> <!-- end li 4B -->
      </ul></li> <!-- end li 3B -->
    </ul></li> <!-- end li 2A -->
  </ul></li> <!-- end li 1B -->
</ul>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,300], 'outline'=>$magenta, 
		  'marker_width'=>8, 'marker_gap'=>4,
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

$content = <<"END_OF_CONTENT";
<h2>Ordered (numbered) lists with various markers</h2>
<ol> <!-- default decimal -->
  <li>Ordered 1A, decimal 1., 2.</li>
  <li>Ordered 1B
  <ol style="list-style-type: upper-roman"> <!-- I, II, III, IV -->
    <li>Ordered 2A, upper-roman I., II.</li>
    <li>Ordered 2B
    <ol style="list-style-type: upper-alpha"> <!-- A, B, C, D -->
      <li>Ordered 3A, upper-alpha A., B.</li>
      <li>Ordered 3B
      <ol style="list-style-type: lower-roman"> <!-- i, ii, iii, iv -->
        <li>Ordered 4A, lower-roman i., ii.</li>
        <li>Ordered 4B
        <ol style="list-style-type: lower-alpha"> <!-- a, b, c, d -->
          <li>Ordered 5A lower-alpha a., b.</li>
          <li>Ordered 5B</li>
	</ol>
        <ol> <!-- default decimal -->
          <li>Ordered 6A, decimal 1., 2.</li>
          <li>Ordered 6B</li>
	</ol></li>
      </ol></li>
    </ol></li>
  </ol></li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,425, 500,265], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

print "======================================================= pg 3\n";
print "---- Mix of ul and ol\n";

$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Mixture of ordered and unordered with DEFAULT markers</h2>
<ol> <!-- default decimal -->
  <li>Ordered 1A, decimal 1., 2.</li>
  <li>Ordered 1B
  <ul> <!-- default circle -->
    <li>Unordered 2A, open circle</li>
    <li>Unordered 2B
    <ol> <!-- default decimal -->
      <li>Ordered 3A, decimal 1., 2.</li>
      <li>Ordered 3B
      <ul> <!-- default (open) box -->
        <li>Unordered 4A, box</li>
        <li>Unordered 4B
        <ol> <!-- default decimal -->
          <li>Ordered 5A, decimal 1., 2.</li>
          <li>Ordered 5B</li>
	</ol>
        <ul> <!-- default (filled) disc -->
          <li>Unordered 6A, disc</li>
          <li>Unordered 6B</li>
	</ul></li>
      </ul></li>
    </ol></li>
  </ul></li>
</ol>

<h2>list-style-position inside and outside, with multiline li's</h2>
<h3>Outside (explicitly)</h3>
<ul style="list-style-position: outside;">
  <li>This is going to show that continuation line(s) of a list item are
  positioned "outside", per the default behavior, although we are explicitly
  giving it in CSS.</li>
  <li>Again, this is going to show that continuation line(s) of a list item are
  positioned "outside", per the default behavior, although we are explicitly
  giving it in CSS.
  <ul style="list-style-position: outside;">
    <li>This is going to show that continuation line(s) of a list item are
    positioned "outside", per the default behavior, although we are explicitly
    giving it in CSS.</li>
    <li>Again, this is going to show that continuation line(s) of a list item are
    positioned "outside", per the default behavior, although we are explicitly
    giving it in CSS.</li>
  </ul></li>
</ul>

<h3>Inside</h3>
<ul style="list-style-position: inside;">
  <li>This is going to show that continuation line(s) of a list item are
  positioned "inside", which we are explicitly giving in CSS.</li>
  <li>Again, this is going to show that continuation line(s) of a list item are
  positioned "inside", which we are explicitly giving in CSS.
  <ul style="list-style-position: inside;">
    <li>This is going to show that continuation line(s) of a list item are
    positioned "inside", which we are explicitly giving in CSS.</li>
    <li>Again, this is going to show that continuation line(s) of a list item are
    positioned "inside", which we are explicitly giving in CSS.</li>
  </ul></li>
</ul>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,650], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

print "======================================================= pg 4\n";
print "---- Extended list-style-position\n";

$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Extended functionality of list-style-position</h2>
<h3>Indented 70% from 'inside' to 'outside'</h3>
<ul style="list-style-position: 70%;">
  <li>This is going to show that continuation line(s) of a list item are
  positioned partially "inside" 70% of the way, which we are explicitly giving in CSS.</li>
  <li>Again, this is going to show that continuation line(s) of a list item are
  positioned partially "inside", which we are explicitly giving in CSS.
  <ul style="list-style-position: 70%;">
    <li>This is going to show that continuation line(s) of a list item are
    positioned "inside" 70% of the way, which we are explicitly giving in CSS.</li>
    <li>Again, this is going to show that continuation line(s) of a list item are
    positioned partially "inside", which we are explicitly giving in CSS.</li>
  </ul></li>
</ul>

<h3>Indented 11pt from 'inside'</h3>
<ul style="list-style-position: 11pt;">
  <li>This is going to show that continuation line(s) of a list item are
  positioned partially "inside" 11 points in, which we are explicitly giving in CSS.</li>
  <li>Again, this is going to show that continuation line(s) of a list item are
  positioned partially "inside", which we are explicitly giving in CSS.
  <ul style="list-style-position: 11pt;">
    <li>This is going to show that continuation line(s) of a list item are
    positioned partially "inside" 11 points in, which we are explicitly giving in CSS.</li>
    <li>Again, this is going to show that continuation line(s) of a list item are
    positioned partially "inside", which we are explicitly giving in CSS.</li>
  </ul></li>
</ul>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,365], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

# try nesting in Markdown
$content = <<"END_OF_CONTENT";
## Try nested Markdown entries (manually indent items)

1. This is a numbered list unnested.
2. This is another item in the numbered list.
   - This is a first nested level bulleted list.
     - This is a further nested bulleted list.
     - And a second item.
   - Back to first nested level bulleted list
3. One last numbered list item
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,350, 500,200], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "list example overflowed column!\n";
}

# Counting down (reversed) ordered lists
print "======================================================= pg 5\n";
print "---- Count down list examples\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>Test reversed ordered lists</h2>
<ol reversed="1" start="10">
  <li>ten</li>
  <li>nine</li>
  <li>eight</li>
  <li>seven</li>
  <li>six</li>
  <li>five
  <ol>
    <li>holding</li>
    <li>resume countdown</li>
  </ol></li>
  <li>four</li>
  <li>three</li>
  <li>two</li>
  <li>one</li>
</ol>
<h2>Reversed ordered list run past 1</h2>
<ol reversed="1" start="3">
  <li>three</li>
  <li>two</li>
  <li>one</li>
  <li>zero... blast off!</li>
  <li>minus one... the clock is running</li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,425], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	          'marker_width'=>1.5*$fs,
	         );
if ($rc) {
    print STDERR "reversed list example overflowed column!\n";
}

print "---- default CSS for Markdown\n";
$content = <<"END_OF_CONTENT";
Ordered list with no margin-top/bottom (extra space between elements)

1. Numbered item 1.
2. Numbered item 2.
3. Numbered item 3.

## And a subheading to make green
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,275, 500,100], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	          'marker_width'=>1.5*$fs,
	         );
if ($rc) { 
    print STDERR "Markdown CSS example overflowed column!\n";
}

print "---- set CSS for Markdown\n";
$content = <<"END_OF_CONTENT";
Ordered list with no margin-top/bottom (no space between elements) and new marker format

1. Numbered item 1.
2. Numbered item 2.
3. Numbered item 3.

## And a subheading to make green
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,165, 500,100], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	          'marker_width'=>1.5*$fs,
		  'style'=>"
        ol { _marker-before: '(' ; _marker-after: ')' ; }
        li { margin-top: 0; margin-bottom: 0 } 
        h2 { color: green; }
       ", 
        # marker-before/after could be in ol, too 
	# note that comments not supported in CSS
	         );
if ($rc) { 
    print STDERR "Markdown CSS example overflowed column!\n";
}

# Setting marker properties 
print "======================================================= pg 6\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

print "---- Marker properties list examples\n";
# 4 with default marker, 5 with explicit marker
$content = <<"END_OF_CONTENT";
<h3>Marker colors and specific text</h3>
<ul style="_marker-color: blue;">
  <li>Why <span style="color: blue;">blue?</span> Why not?</li>
  <_marker style="_marker-color: red;"><li>Oh, oh, <span style="color: red;">red</span> means trouble!</li>
  <_marker style="_marker-color: yellow;"><li>A color of <span style="color: yellow;">yellow</span> means caution.</li>
  <_marker style="_marker-color: green;"><li>A color of <span style="color: green;">green</span> means full speed ahead.</li>
  <li>And back to <span style="color: blue;">blue</span> again.
  <ul style="_marker-color: ''; _marker-text: '*'; _marker-font: 'ZapfDingbats';">
    <li>Back to normal black markers,</li>
    <_marker style="_marker-text: '+';"><li>but wait, what's with the marker text?...</li>
    <_marker style="_marker-text: '=>'; _marker-font: 'Times';"><li>Not to mention multiple character strings!</li>
  </ul></li>
  <li>See? <span style="color: blue;">blue</span> markers again</li>
</ul>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,215], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) {
    print STDERR "marker properties list 1 example overflowed column!\n";
}

$content = <<"END_OF_CONTENT";
<h3>Marker size, weight, font, style</h3>
<h3>Notice that the marker_width needs to be set wider than default</h3>
<ol style="_marker-font: sans-serif; _marker-size: 60%; _marker-weight: bold; 
           list-style-type: upper-roman; _marker-before: '('; 
           _marker-after: ')'; _marker-style: italic;" start="1997">
                   <li>Mildly concerned</li>
  <li>Quite concerned</li>
  <li>Panic time!</li>
  <li>That wasn't as bad as feared</li>
  <li>Start worrying about Y2K38</li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,515, 500,160], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ], 'marker_width'=>50 );
if ($rc) {
    print STDERR "marker properties list 2 example overflowed column!\n";
}

print "---- Simple list examples\n";
$content = <<"END_OF_CONTENT";
<h3>Simple lists</h3>
<ul style="list-style-type: none; list-style-position: inside;">
  <li><b>U1A ul with "none" type, positioned inside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
  <li><b>U1B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? OK, now it is.</li>
  <ul style="list-style-type: none;">
    <li><b>U2A ul with "none" type, positioned outside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
    <li><b>U2B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough?</li>
  </ul>
</ul> <!-- REPEAT with <_sl>, should look the same as above ============= -->
<_sl style="list-style-position: inside;">
  <li><b>S1A _sl, positioned inside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
  <li><b>S1B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? Apparently it wasn't.</li>
  <_sl>
    <li><b>S2A _sl, positioned outside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
    <li><b>S2B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? Now it is.</li>
  </_sl>
</_sl>
END_OF_CONTENT

if (0) {
	# extra test material to append to above
$content = <<"END_OF_CONTENT";
<!-- see how HTML::TreeBuilder handles this -->
<ul>
	<li>Item A1</li>
	<_marker><li>Item A2 with marker</li>
	<_marker></_marker><li>Item A3 with full marker</li>
	<_marker>*</_marker><li>Item A4 with full marker and text (notice * in Zapf Dingbats font)</li>
	<!-- remember, this is ZapfDingbats font, * is a filled pointing hand -->
</ul>
<_sl>
	<li>Item B1</li>
	<_marker><li>Item B2 with marker</li>
	<_marker></_marker><li>Item B3 with full marker</li>
	<_marker>*</_marker><li>Item B4 with full marker and text (text removed for simple list)</li>
	<!-- _marker text forced to '' -->
</_sl>
<!-- check also ul and sl IN li -->
<ul style="list-style-type: none; list-style-position: inside;">
  <li><b>U3A ul with "none" type, positioned inside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
  <li><b>U3B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? Not quite. OK, now it is.
  <ul style="list-style-type: none;">
    <li><b>U4A ul with "none" type, positioned outside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
    <li><b>U4B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough?</li>
  </ul></li>
</ul> <!-- REPEAT with <_sl>, should look the same as above ============= -->
<_sl style="list-style-position: inside;">
  <li><b>S3A _sl, positioned inside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
  <li><b>S3B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? Apparently it wasn't.
  <_sl>
    <li><b>S4A _sl, positioned outside.</b> Let's have enough content to wrap around to a second line. Is this enough?</li>
    <li><b>S4B</b> Let's have enough content to wrap around to a second line. Add some more. Is this enough? Now it is.</li>
  </_sl></li>
</_sl>
END_OF_CONTENT
}

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,335, 500,300], 'outline'=>$magenta, 
#                 'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ], );
if ($rc) {
    print STDERR "simple list example overflowed column!\n";
}

# Checking behavior in lists split across columns
print "======================================================= pg 7\n";
print "---- List behavior when split across columns\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

# <ul> nested two deep, split there and other places. making sure that
#  superfluous bullets or other problems don't show up
# first column this depth, remainder to second column
my $entire_depth = 350;
my $top_depth = 
#   60;  # inside top level entry 1
#   80;  # between top level entry 1 and 2
   140;  # inside nested level entry 1
#  165;  # between nested level entry 1 and its paragraph
#  180;  # inside paragraph
#  205;  # after nested level entry 1
#  230;  # inside nested level entry 2
#  $entire_depth;  # entire thing

$content = <<"END_OF_CONTENT";
<h2>List split across columns</h2>
<ul>
  <li>&lt;ul&gt; top level, entry 1.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</li>
<li>&lt;ul&gt; top level, entry 2.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</li>
    <ul>
      <li>&lt;ul&gt; nested level, entry 1.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.
      <p>This should start a new paragraph. 
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</p></li>
      <li>&lt;ul&gt; nested level, entry 2.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</li>
    </ul>
  <li>&lt;ul&gt; top level, entry 3.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</li>
  <li>&lt;ul&gt; top level, entry 4.
  Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo.</li>
</ul>
END_OF_CONTENT

# notice the non-zero paragraph top margin
print "...first column\n";
restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,$top_depth], 'outline'=>$magenta, 
		  'para'=>[ 0, 2 ] );

if ($top_depth < $entire_depth) {
    print "...second column\n";
    ($rc, $next_y, $unused) =
        $text->column($page, $text, $grfx, 'pre', $unused, 
 	              'rect'=>[50,750-$top_depth-10, 
			       500,$entire_depth-$top_depth], 
		      
		      'outline'=>$magenta, 'para'=>[ 0, 2 ],
	     );

   if ($rc) {
       print STDERR "split list check example overflowed column!\n";
   }
}

$content = <<"END_OF_CONTENT";
<h3>Marker alignment</h3>
<h4>Notice that the marker_width needs to be set wider than default</h4>
<ol style="_marker-font: sans-serif; _marker-size: 60%; _marker-weight: bold; 
           list-style-type: upper-roman; _marker-before: '('; 
	   _marker-align: left;
           _marker-after: ')'; _marker-style: italic;" start="1997">
  <li><b>left justified</b> Mildly concerned</li>
  <li>Quite concerned</li>
  <li>Panic time!</li>
  <li>That wasn't as bad as feared</li>
  <li>Start worrying about Y2K38</li>
</ol>
<ol style="_marker-font: sans-serif; _marker-size: 60%; _marker-weight: bold; 
           list-style-type: upper-roman; _marker-before: '('; 
	   _marker-align: center;
           _marker-after: ')'; _marker-style: italic;" start="1997">
  <li><b>center justified</b> Mildly concerned</li>
  <li>Quite concerned</li>
  <li>Panic time!</li>
  <li>That wasn't as bad as feared</li>
  <li>Start worrying about Y2K38</li>
</ol>
<ol style="_marker-font: sans-serif; _marker-size: 60%; _marker-weight: bold; 
           list-style-type: upper-roman; _marker-before: '('; 
	   _marker-align: right;
           _marker-after: ')'; _marker-style: italic;" start="1997">
  <li><b>right justified (default, explicitly given)</b> Mildly concerned</li>
  <li>Quite concerned</li>
  <li>Panic time!</li>
  <li>That wasn't as bad as feared</li>
  <li>Start worrying about Y2K38</li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,380, 500,340], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ], 'marker_width'=>75 );
if ($rc) {
    print STDERR "marker-align example overflowed column!\n";
}

print "======================================================= pg 8\n";
print "---- Ordered list behavior with li value and type\n";
$page = $pdf->page();
$text = $page->text();
$grfx = $page->gfx();

$content = <<"END_OF_CONTENT";
<h2>OL with LI value, type attributes</h2>
<ol>
  <li>Item 1</li>
  <li value="17">Item 2 is overridden by value="17"</li>
  <li type="i">Item 18 formatted as 'xviii' due to type="i"</li>
  <li type="A" value="4">Item 19 override to 4 and formatted as 'D' due to type="A"</li>
</ol>
<h3>OL with type attribute</h3>
<ol type="I">
  <li>Item I.</li>
  <li>Item II.</li>
  <li>Item III.</li>
</ol>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,220], 'outline'=>$magenta, 
		  'marker_width'=>48 );

   if ($rc) {
       print STDERR "ol with li value, type overflowed column!\n";
   }

# ---------------------------------------------------------------------------
# end of program
$pdf->saveas($name);
# -----------------------

# pause during debug
sub pause {
    print STDERR "=====> Press Enter key to continue...";
    my $input = <>;
    return;
}

#   restore font and color in case previous column left it in an odd state.
#   the default behavior is to use whatever font and color was left from any
#     previous operation (not necessarily a column() call) unless it was 
#     overridden by various settings.
sub restore_props {
    my ($text, $grfx) = @_;

#   $text->fillcolor('black');
#   $grfx->strokecolor('black');
    # italic and bold get reset to 'normal' anyway on column() entry,
    # but need to fix font face in case it was left something odd
#   $text->font($pdf->get_font('face'=>'default', 'italic'=>0, 'bold'=>0), 12);

    return;
}
