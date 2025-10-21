#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/43OuNT/2
my $tests = 
[
    {
        katex_all       => "\$\$\n\\Gamma(z) = \\int_0^\\infty t^{z-1}e^{-t}dt\\,.\n\$\$\n",
        katex_close     => "\$\$",
        katex_content   => "\\Gamma(z) = \\int_0^\\infty t^{z-1}e^{-t}dt\\,.",
        katex_open      => "\$\$",
        name            => "Double quote block",
        test            => <<'EOT',
$$
\Gamma(z) = \int_0^\infty t^{z-1}e^{-t}dt\,.
$$
EOT
    },
    {
        katex_all       => "\$math with a\n      \\\$ sign\$",
        katex_close     => "\$",
        katex_content   => "math with a\n      \\\$ sign",
        katex_open      => "\$",
        name            => "Multiline with escaped dollar",
        test            => <<'EOT',
And $math with a
      \$ sign$.
EOT
    },
    {
        katex_all       => "\$math \\frac12\$",
        katex_close     => "\$",
        katex_content   => "math \\frac12",
        katex_open      => "\$",
        name            => "Inline with single dollar delimiter",
        test            => q{This is some text $math \frac12$},
    },
    {
        katex_all       => "\$\\unsupported\$",
        katex_close     => "\$",
        katex_content   => "\\unsupported",
        katex_open      => "\$",
        name            => "Inline with single dollar delimiter and escaped sequence",
        test            => q{other text $\unsupported$},
    },
    {
        katex_all       => "\\[ displaymath \\[\\]",
        katex_close     => "\\]",
        katex_content   => " displaymath \\[",
        katex_open      => "\\[",
        name            => "Inline with square brackets and escaped sequences",
        test            => q{Other node \[ displaymath \\[\\] \frac{1}{2} \] blah},
    },
    {
        katex_all       => "\\(and math\\)",
        katex_close     => "\\)",
        katex_content   => "and math",
        katex_open      => "\\(",
        name            => "Inline with parenthesis",
        test            => q{more text \(and math\) blah},
    },
    {
        katex_all       => "\$\$ \\int_2^3 \$\$",
        katex_close     => "\$\$",
        katex_content   => " \\int_2^3 ",
        katex_open      => "\$\$",
        name            => "Inline with double dollar delimiters",
        test            => q{$$ \int_2^3 $$},
    },
];

my $tests2 =
[
    {
        fail            => 1,
        test            => q{LD_PRELOAD=libusb-driver.so $0.bin $*},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtKatex},
    type => 'Katex',
});

run_tests( $tests2,
{
    debug => 1,
    re => $RE{Markdown}{ExtKatex}{-delimiter => '$$,$$,\[,\]'},
    type => 'Katex with limited delimiters',
});

