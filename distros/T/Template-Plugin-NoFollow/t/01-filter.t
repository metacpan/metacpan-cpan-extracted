use strict;
use warnings;
use Template;
use Test::More tests => 9;

my $text     = '<a href="http://www.google.com/">Google</a>';
my $expected = '<a rel="nofollow" href="http://www.google.com/">Google</a>';

###############################################################################
# Make sure that TT works.
check_tt: {
    my $tt = Template->new();
    my $template = qq{hello world!};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $template, 'TT works' );
}

###############################################################################
# Use NoFollow as a FILTER
filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE NoFollow -%]
[%- FILTER nofollow -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Works in [% FILTER ... %] block' );
}

###############################################################################
# Use as named FILTER
named_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE foo = NoFollow -%]
[%- FILTER \$foo -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Works in named [% FILTER ... %] block' );
}

###############################################################################
# Use as inline filter
filter_inline: {
    my $tt = Template->new();
    my $template = qq{
[%- USE NoFollow -%]
[%- text | nofollow -%]
};
    my $output;
    $tt->process( \$template, { 'text' => $text }, \$output );
    is( $output, $expected, 'Works as inline filter' );
}

###############################################################################
# Use as named inline filter
named_filter_inline: {
    my $tt = Template->new();
    my $template = qq{
[%- USE foo = NoFollow -%]
[%- text | \$foo -%]
};
    my $output;
    $tt->process( \$template, { 'text' => $text }, \$output );
    is( $output, $expected, 'Works as named inline filter' );
}

###############################################################################
# Filter <A> already set up with rel="nofollow"; gets moved, but is preserved
has_nofollow: {
    my $tt = Template->new();
    my $template = qq{[% USE NoFollow %][%- text | nofollow -%]};
    my $text     = qq{<a href="_href" rel="nofollow">foo</a>};
    my $expected = qq{<a rel="nofollow" href="_href">foo</a>};
    my $output;
    $tt->process( \$template, { 'text' => $text }, \$output );
    is( $output, $expected, 'Works if already has rel="nofollow"' );
}

###############################################################################
# Filter <A> tags with attributes in various orders
attribute_ordering: {
    my $tt = Template->new();
    my $template = qq{[% USE NoFollow %][%- text | nofollow -%]};

    a_href_alt: {
        my $output;
        my $text     = qq{<a href="_href" alt="_alt">foo</a>};
        my $expected = qq{<a rel="nofollow" href="_href" alt="_alt">foo</a>};
        $tt->process( \$template, { 'text' => $text }, \$output );
        is( $output, $expected, 'Works as <A HREF=... ALT=...>' );
    }

    a_alt_href: {
        my $output;
        my $text     = qq{<a alt="_alt" href="_href">foo</a>};
        my $expected = qq{<a rel="nofollow" alt="_alt" href="_href">foo</a>};
        $tt->process( \$template, { 'text' => $text }, \$output );
        is( $output, $expected, 'Works as <A ALT=... HREF=...>' );
    }

    a_onclick: {
        my $output;
        my $text     = qq{<a onclick="_onclick">foo</a>};
        my $expected = qq{<a rel="nofollow" onclick="_onclick">foo</a>};
        $tt->process( \$template, { 'text' => $text }, \$output );
        is( $output, $expected, 'Works as <A ONCLICK=...>' );
    }
}
