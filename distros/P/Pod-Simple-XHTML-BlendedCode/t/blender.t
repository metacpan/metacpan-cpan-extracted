#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use Test::LongString;
use IO::String qw();
use Pod::Simple::XHTML::BlendedCode::Blender 1.000 qw();

my $parser = Pod::Simple::XHTML::BlendedCode::Blender->new();

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

my $pod        = q{};
my $pod_handle = IO::String->new($pod);
my $in_handle  = IO::String->new($input); 

my $preprocessor = Pod::Simple::XHTML::BlendedCode::Blender->new();
$preprocessor->parseopts( '-want_nonPODs' => 1 );
$preprocessor->parse_from_file( $in_handle, $pod_handle );

is_string($pod, <<'END_OF_EXPECTED_TEST_OUTPUT', 'blender works');
=begin html

<pre>
<span class="keyword">package</span> <span class="word">Test::Package</span><span class="structure">;</span>
</pre>

=end html

=pod

=head1 NAME

Test::Package - This is a test string.

=begin html

<pre>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_modules_hash</span><span class="structure">({</span>
&nbsp;&nbsp;&nbsp;&nbsp;<span class="single">'Pod::Simple::XHTML::BlendedCode(.*)?'</span> <span class="operator">=&gt;</span> <span class="single">'Pod-Simple-XHTML-BlendedCode/'</span><span class="operator">,</span>
<span class="structure">});</span>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_url_postfix</span><span class="structure">(</span><span class="single">'.pm.html'</span><span class="structure">);</span>
<span class="symbol">$parser</span><span class="operator">-&gt;</span><span class="word">internal_url_prefix</span><span class="structure">(</span><span class="single">'http://csjewell.comyr.com/perl/'</span><span class="structure">);</span>
</pre>

=end html

=head1 DOCUMENTATION

This is to test the operation of Pod::Simple::XHTML::BlendedCode.

L<Pod::Simple|Pod::Simple> is (ab)used.

=begin html

<pre>
<span class="number">1</span><span class="structure">;</span>
</pre>

=end html

END_OF_EXPECTED_TEST_OUTPUT
