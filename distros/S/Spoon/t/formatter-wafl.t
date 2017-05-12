use lib 't', 'lib';
use strict;
use warnings;
use Spoon;

use Test::More tests => 6;
use Formatter;

my $hub = Spoon->new->load_hub(
    {
        formatter_class => 'Test::Formatter',
    }
);

my $formatter = $hub->formatter;

{
    my $html = $formatter->text_to_html(<<'EOF');
{phrase1: testing}
EOF

    like( $html, qr{<span class="phrase1">testing</span>},
          'Basic WAFL phrase formatting' );
}

{
    my $html = $formatter->text_to_html(<<'EOF');
{Phrase1: testing}
EOF

    like( $html, qr{<span class="phrase1">testing</span>},
          'Basic WAFL phrase formatting - case insensitive' );
}


{
    my $html = $formatter->text_to_html(<<'EOF');
.block1
block contents
.block1
EOF

    like( $html, qr{<div class="block1">\s*block contents\s*</div>}s,
          'Basic WAFL block formatting' );
}

{
    my $html = $formatter->text_to_html(<<'EOF');
.blOCK1
block contents
.blOCK1
EOF

    like( $html, qr{<div class="block1">\s*block contents\s*</div>}s,
          'Basic WAFL block formatting - case insensitive' );
}

{
    my $html = $formatter->text_to_html(<<'EOF');
{underline_name: testing}
EOF

    like( $html, qr{<span class="underline_name">testing</span>}s,
          'underline in wafl name' );
}

{
    my $html = $formatter->text_to_html(<<'EOF');
{underline-name: testing}
EOF

    like( $html, qr{<span class="underline_name">testing</span>}s,
          'dash in wafl name' );
}
