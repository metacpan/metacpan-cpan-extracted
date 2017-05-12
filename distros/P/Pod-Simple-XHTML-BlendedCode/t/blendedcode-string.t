#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Test::LongString;
use IO::CaptureOutput qw(capture);
use Pod::Simple::XHTML::BlendedCode 1.000 qw();

my $parser = Pod::Simple::XHTML::BlendedCode->new();
$parser->internal_url_divide_slashes(0);

my $input = <<'TEST_INPUT';
package Test::Package;

=pod

=head1 NAME

Test::Package - This is a test string.

=cut

$parser->internal_modules_hash({
	'Pod::Simple::XHTML::BlendedCode(.*)?' => 'Pod-Simple-XHTML-BlendedCode/',
});
$parser->internal_url_postfix('.pm.html');
$parser->internal_url_prefix('http://csjewell.comyr.com/perl/');

=head1 DOCUMENTATION

This is to test the operation of Pod::Simple::XHTML::BlendedCode.

L<Pod::Simple|Pod::Simple> is (ab)used.

=cut

1;

TEST_INPUT

my $output_test;
capture { $parser->parse_string_document($input) } \$output_test;

print $output_test;

is_string($output_test, <<'END_OF_EXPECTED_TEST_OUTPUT', 'parse_string_document works');

<html>
<head>
<title></title>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />
</head>
<body>




<pre>
<span class="keyword">package</span> <span class="word">Test::Package</span><span class="structure">;</span>
</pre>

<h1 id="NAME">NAME</h1>

<p>Test::Package - This is a test string.</p>



<pre>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_modules_hash</span><span class="structure">({</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="single">'Pod::Simple::XHTML::BlendedCode(.*)?'</span> <span class="operator">=&gt;</span> <span class="single">'Pod-Simple-XHTML-BlendedCode/'</span><span class="operator">,</span>
<span class="structure">});</span>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_url_postfix</span><span class="structure">(</span><span class="single">'.pm.html'</span><span class="structure">);</span>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_url_prefix</span><span class="structure">(</span><span class="single">'http://csjewell.comyr.com/perl/'</span><span class="structure">);</span>
</pre>

<h1 id="DOCUMENTATION">DOCUMENTATION</h1>

<p>This is to test the operation of Pod::Simple::XHTML::BlendedCode.</p>

<p><a href="http://search.cpan.org/perldoc?Pod::Simple">Pod::Simple</a> is (ab)used.</p>



<pre>
<span class="number">1</span><span class="structure">;</span>
</pre>

</body>
</html>

END_OF_EXPECTED_TEST_OUTPUT
