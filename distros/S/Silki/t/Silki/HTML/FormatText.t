use strict;
use warnings;

use Test::Most;

use Silki::HTML::FormatText;

my $formatter = Silki::HTML::FormatText->new( leftmargin => 0 );

{
    my $html = <<'EOF';
<p>Has an <em>emph</em> string</p>
EOF

    my $expect = <<'EOF';
Has an emph string
EOF

    is(
        trim_ws( $formatter->format_string($html) ),
        $expect,
        'simple paragraph with em tag'
    );
}

{
    my $html = <<'EOF';
<p>Has a <a href="http://example.com">link</a>.</p>
EOF

    my $expect = <<'EOF';
Has a link (http://example.com).
EOF

    is(
        trim_ws( $formatter->format_string($html) ),
        $expect,
        'paragraph with a link'
    );
}

{
    my $html = <<'EOF';
<p>Has an <a name="foo">anchor</a>.</p>
EOF

    my $expect = <<'EOF';
Has an anchor.
EOF

    is(
        trim_ws( $formatter->format_string($html) ),
        $expect,
        'paragraph with an anchor'
    );
}

sub trim_ws {
    my $text = shift;

    $text =~ s/^\n+//;
    $text =~ s/\n+$/\n/;

    return $text;
}

done_testing();
