#! perl
#
# Test for markdown filter

use strict;
use warnings;

use Template::Flute;
use Test::More;
use Class::Load qw(try_load_class);
use HTML::Entities;

try_load_class('HTML::Scrubber')
    or plan skip_all => "Missing HTML::Scrubber module.";

try_load_class('Text::Markdown')
    or plan skip_all => "Missing Text::Markdown module.";

plan tests => 3;

# markdown filter
my $xml = <<EOF;
<specification name="filters">
    <value name="text" filter="markdown" />
</specification>
EOF

my $html = <<EOF;
    <div class="text">foo</div>
EOF

my $tests = {
    '#this is H1'  => '<h1>this is H1</h1>',
    '* item'       => "<ul><li>item</li></ul>",
    '> this is blockquote' => "<blockquote><p>this is blockquote</p></blockquote>",
};

for my $key ( keys %$tests ) {
    my $flute = Template::Flute->new(
        specification => $xml,
        template      => $html,
        values        => { text => $key }
    );

    my $ret = $flute->process();

    $ret =~ s/>[\h\v]+/>/g; #remove white space
    $ret =~ tr/\r\n//d; #remove new line
    my $html_text = decode_entities($ret);

    ok($html_text =~ m{$tests->{$key}}, "markdown filter: $html_text")
        || diag "Expected $tests->{$key} instead of $html_text.";

}
