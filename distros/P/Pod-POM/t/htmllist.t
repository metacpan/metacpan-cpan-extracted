#!/usr/bin/perl -w                                         # -*- perl -*-
#
# test the generation of HTML lists

use strict;
use lib qw( ./lib ../lib );
use Pod::POM;
use Pod::POM::View::HTML;
use Pod::POM::Test;

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML';

ntests(2);

my $text;
{   local $/ = undef;
    $text = <DATA>;
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

match($result, $expect);
#print $pom;

__DATA__
=head1 Test

=over 4

=item *

The first item

=item *

The second item

=back

=over 4

=item 1

The 1st item

=item 2

The 2nd item

=back

=over 4

=item 1.

The 1st item

=item 2.

The 2nd item

=back

=over 4

=item foo

The foo item

=item bar

The bar item

=item crash bang wallop!

The crazy item

=back

------------------------------------------------------------------------

<html>
<body bgcolor="#ffffff">
<h1>Test</h1>

<ul>
<li>
<p>The first item</p>
</li>
<li>
<p>The second item</p>
</li>
</ul>
<ol>
<li>
<p>The 1st item</p>
</li>
<li>
<p>The 2nd item</p>
</li>
</ol>
<ol>
<li>
<p>The 1st item</p>
</li>
<li>
<p>The 2nd item</p>
</li>
</ol>
<ul>
<li><a name="item_foo"></a><b>foo</b>
<p>The foo item</p>
</li>
<li><a name="item_bar"></a><b>bar</b>
<p>The bar item</p>
</li>
<li><a name="item_crash_bang_wallop_"></a><b>crash bang wallop!</b>
<p>The crazy item</p>
</li>
</ul>
</body>
</html>

