use Test::More tests => 1;

use Swim;

my $swim = "foo";
my $html = Swim->new(text => $swim)->to_html;
is $html, "<p>foo</p>\n",
    "Trailing newline not needed";
