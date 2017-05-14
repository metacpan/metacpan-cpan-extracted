use strict;
use warnings;
sub basic_html_tests {
    my $hl = shift;

    my $sample = q{my $x = 42;};

    my $html1 = $hl->htmlize_string($sample, 'pl');
    like("$html1",
	 qr,^<pre><font color="#[[:xdigit:]]{6}">my</font> \$<font color="#[[:xdigit:]]{6}">x</font> = 42;</pre>$,,
	 'html-font');

    $hl->mode('css');
    my ($html2, $css2) = $hl->htmlize_string($sample, 'pl');
    ok("$html2" =~
	   m,^<pre><span class="(type|keyword)">my</span> \$<span class="variable-name">x</span> = 42;</pre>$,,
       'html-css');
    my $class = $1;

    ok(exists $css2->{pre}{'background-color'}, 'background-color');

    like($css2->{".$class"}{color}, qr/^#[[:xdigit:]]{6}$/, 'css');
}
1
