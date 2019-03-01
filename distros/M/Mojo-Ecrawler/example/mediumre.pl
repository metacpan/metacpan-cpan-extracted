#!/usr/bin/perl

use Mojo::Ecrawler;


open my $FD,"<",shift or die "Could't open the file";

my @content=<$FD>;

for(@content) {

# <hx></hx>

s/<h/\n<h/g;
s/(<\/h.>)/\1\n/g;
s/<h1[^>]*>(.*)<\/h1>/\n# \1\n/g;
s/<h2[^>]*>(.*)<\/h2>/\n## \1\n/g;
s/<h3[^>]*>(.*)<\/h3>/\n### \1\n/g;
s/<h4[^>]*>(.*)<\/h4>/\n#### \1\n/g;

s/<strong[^>]*>//g;
s/<\/strong>//g;

s/<pre[^>]*>/\n`/g;
s/<\/pre>/`\n\n/g;

s/<em[^>]*>/`/g;
s/<\/em>/`/g;

s/<p[^>]*>//g;
s/<\/p>/\n/g;

s/<ul[^>]*>//g;
s/<li[^>]*>/\n- /g;
s/<\/li>/\n/g;
s/<\/ul>/\n/g;

s/<a.*href="([^"]*)"[^>]*>(.*)<\/a>/[\2](\1)/g;

s/<div class="aspectRatioPlaceholder-fill".*<\/div>//;
s/<img class="progressiveMedia-thumbnail.*<\/noscript>//;
s/<iframe allowfullscreen.*<\/iframe>//;
s/<a.*href="(.*)[^>]*>(.*)<\/a>/[\{2}](\{1})/;

s/<br>/\n/g;


print;
}

=cut
$re1  = "div.section-inner";
$re2  = "div";

my $pcout1 = getdiv( $pcontent, $re1, $re2, 1 );

print $pcout1;
print "get $lurl  ok \n";

