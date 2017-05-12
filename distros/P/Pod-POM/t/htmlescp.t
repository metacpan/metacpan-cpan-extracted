#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM;
use Pod::POM::View::HTML;
use Pod::POM::Test;

ntests(2);

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML';

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
=head1 NAME

I am a stupid fool who puts naked < & > characters in my POD
instead of escaping them as E<lt> and E<gt>.

Here is some B<bold> text, some I<italic> plus F</etc/fstab>
file and something that looks like an E<lt>htmlE<gt> tag.
This is some C<$code($arg1)>.

------------------------------------------------------------------------

<html>
<body bgcolor="#ffffff">
<h1>NAME</h1>

<p>I am a stupid fool who puts naked &lt; &amp; &gt; characters in my POD
instead of escaping them as &lt; and &gt;.</p>
<p>Here is some <b>bold</b> text, some <i>italic</i> plus <i>/etc/fstab</i>
file and something that looks like an &lt;html&gt; tag.
This is some <code>$code($arg1)</code>.</p>
</body>
</html>

