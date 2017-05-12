#!perl -w

use strict;
use warnings;

use Test::More tests => 1;

use Template;

my $tt = Template->new({
    PLUGINS => {
        'Text::Widont' => 'Template::Plugin::Text::Widont',
    },
});

my $input = <<'END_OF_INPUT';
<h1>
    [%- USE Text::Widont nbsp => 'html' %]
    [% "If the world didn't suck, we'd all fall off!" | widont %]
</h1>
END_OF_INPUT

my $output;
$tt->process( \$input, {}, \$output ) || die $tt->error(), "\n";

my $expected = <<'END_OF_EXPECTED';
<h1>
    If the world didn't suck, we'd all fall&nbsp;off!
</h1>
END_OF_EXPECTED

is( $output, $expected, 'Filter works as expected' );
