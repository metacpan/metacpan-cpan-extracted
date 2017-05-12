#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use utf8;

use lib qw( ./lib ../lib );

use Encode;
use Pod::POM;
use Pod::POM::View::HTML;
use Pod::POM::Test;

ntests(2);

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML';

my $text;
{   local $/ = undef;
    $text = <DATA>;
    Encode::_utf8_on($text);
}
my ($test, $expect) = split(/\s*-------+\s*/, $text);

my $parser = Pod::POM->new();

my $pom = $parser->parse_text($test);

assert( $pom );

my $result = "$pom";

for ($result, $expect) {
    s/^\s*//;
    s/\s*$//;
}

#match($result, $expect);
use constant HAS_TEXT_DIFF => eval { require Text::Diff};
if (HAS_TEXT_DIFF) {
    diff($expect, $result, 2);
} else {
    match($result, $expect);
}

sub diff {
    my($expect, $result, $tnum) = @_;
    my $diff = Text::Diff::diff(\$expect, \$result, {STYLE=> "Unified"});
    if ($diff) {
        print "not ok $tnum\n";
        print $diff;
    }
    else {
        print "ok $tnum\n";
    }
}

#print $pom;

__DATA__
=encoding utf8

=head1 NAME

Test

=head1 SYNOPSIS

    use My::Module;

    my $module = My::Module->new();

=head1 DESCRIPTION

This is the description.

    Here is a verbatim section.
    And we ♥ utf-8 here.

This is some more regular text.

Here is some B<bold> text, some I<italic> and something that looks 
like an E<lt>htmlE<gt> tag.  This is some C<$code($arg1)>.

This C<text contains embedded B<bold> and I<italic> tags>.  These can 
be nested, allowing B<bold and I<bold E<amp> italic> text>.  The module also
supports the extended B<< syntax >> and permits I<< nested tags E<amp>
other B<<< cool >>> stuff >>

=head1 METHODS =E<gt> OTHER STUFF

Here is a list of methods

=head2 new()

Constructor method.  Accepts the following config options:

=over 4

=item foo

The foo item.

=item bar

The bar item.

=over 4

This is a list within a list 

=item *

The wiz item.

=item *

The waz item.

=back

=item baz

The baz item.

=back

Title on the same line as the =item + * bullets

=over

=item * C<Black> Cat

=item * Sat S<I<on> the>

=item * MatE<lt>!E<gt>

=back

Title on the same line as the =item + numerical bullets

=over

=item 1 Cat

=item 2 Sat

=item 3 Mat

=back

No bullets, no title

=over

=item

Cat

=item

Sat

=item

Mat

=back

=head2 old()

Destructor method

=head1 TESTING FOR AND BEGIN

=for html    <br>
<p>
blah blah
</p>

intermediate text

=begin html

<more>
HTML
</more>

some text

=end

=head1 TESTING URLs hyperlinking

This is an href link1: http://example.com

This is an href link2: http://example.com/foo/bar.html

This is an email link: mailto:foo@bar.com

=head1 SEE ALSO

See also L<Test Page 2|pod2>, the L<Your::Module> and L<Their::Module>
manpages and the other interesting file F</usr/local/my/module/rocks>
as well.

=cut

------------------------------------------------------------------------

<html>
<body bgcolor="#ffffff">
<h1>NAME</h1>

<p>Test</p>
<h1>SYNOPSIS</h1>

<pre>    use My::Module;

    my $module = My::Module-&gt;new();</pre>

<h1>DESCRIPTION</h1>

<p>This is the description.</p>
<pre>    Here is a verbatim section.
    And we &#x2665; utf-8 here.</pre>

<p>This is some more regular text.</p>
<p>Here is some <b>bold</b> text, some <i>italic</i> and something that looks 
like an &lt;html&gt; tag.  This is some <code>$code($arg1)</code>.</p>
<p>This <code>text contains embedded <b>bold</b> and <i>italic</i> tags</code>.  These can 
be nested, allowing <b>bold and <i>bold &amp; italic</i> text</b>.  The module also
supports the extended <b>syntax</b> and permits <i>nested tags &amp;
other <b>cool</b> stuff</i></p>
<h1>METHODS =&gt; OTHER STUFF</h1>

<p>Here is a list of methods</p>
<h2>new()</h2>
<p>Constructor method.  Accepts the following config options:</p>
<ul>
<li><a name="item_foo"></a><b>foo</b>
<p>The foo item.</p>
</li>
<li><a name="item_bar"></a><b>bar</b>
<p>The bar item.</p>
<ul>
<p>This is a list within a list</p>
<li>
<p>The wiz item.</p>
</li>
<li>
<p>The waz item.</p>
</li>
</ul>
</li>
<li><a name="item_baz"></a><b>baz</b>
<p>The baz item.</p>
</li>
</ul>
<p>Title on the same line as the =item + * bullets</p>
<ul>
<li><a name="item__code_Black__code__Cat"></a><b><code>Black</code> Cat</b>
</li>
<li><a name="item_Sat__i_on__i__nbsp_the"></a><b>Sat <i>on</i>&nbsp;the</b>
</li>
<li><a name="item_Mat_lt___gt_"></a><b>Mat&lt;!&gt;</b>
</li>
</ul>
<p>Title on the same line as the =item + numerical bullets</p>
<ol>
<li><a name="item_Cat"></a><b>Cat</b>
</li>
<li><a name="item_Sat"></a><b>Sat</b>
</li>
<li><a name="item_Mat"></a><b>Mat</b>
</li>
</ol>
<p>No bullets, no title</p>
<ul>
<li>
<p>Cat</p>
</li>
<li>
<p>Sat</p>
</li>
<li>
<p>Mat</p>
</li>
</ul>
<h2>old()</h2>
<p>Destructor method</p>
<h1>TESTING FOR AND BEGIN</h1>

<br>
<p>
blah blah
</p>

<p>intermediate text</p>
<more>
HTML
</more>
some text
<h1>TESTING URLs hyperlinking</h1>

<p>This is an href link1: <a href="http://example.com">http://example.com</a></p>
<p>This is an href link2: <a href="http://example.com/foo/bar.html">http://example.com/foo/bar.html</a></p>
<p>This is an email link: <a href="mailto:foo@bar.com">mailto:foo@bar.com</a></p>
<h1>SEE ALSO</h1>

<p>See also <i>Test Page 2</i>, the <i>Your::Module</i> and <i>Their::Module</i>
manpages and the other interesting file <i>/usr/local/my/module/rocks</i>
as well.</p>
</body>
</html>

