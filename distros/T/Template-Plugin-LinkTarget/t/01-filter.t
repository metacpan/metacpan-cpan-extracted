use strict;
use warnings;
use Template;
use Test::More tests => 11;

my $text     = qq{<a href="http://www.google.com/">Google</a>};
my $expected = qq{<a href="http://www.google.com/" target="_blank">Google</a>};

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
# Use LinkTarget as a FILTER
filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE LinkTarget -%]
[%- FILTER linktarget -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, '[% FILTER ... %] block' );
}

###############################################################################
# Use as named FILTER
named_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE tgt = LinkTarget -%]
[%- FILTER \$tgt -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Named [% FILTER ... %] block' );
}

###############################################################################
# Use as inline filter
inline_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE LinkTarget -%]
[%- text | linktarget -%]
};
    my $output;
    $tt->process( \$template, { text => $text }, \$output );
    is( $output, $expected, 'Inline filter' );
}

###############################################################################
# Use as named inline filter
named_inline_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE tgt = LinkTarget -%]
[%- text | \$tgt -%]
};
    my $output;
    $tt->process( \$template, { text => $text }, \$output );
    is( $output, $expected, 'Named inline filter' );
}

###############################################################################
# Filter <A> already set up with "target" attribute; gets replaced
has_target: {
    my $tt = Template->new();
    my $template = qq{[% USE LinkTarget %][%- text | linktarget -%]};
    my $text     = qq{<a target="_top" href="_href">foo</a>};
    my $expected = qq{<a target="_blank" href="_href">foo</a>};
    my $output;
    $tt->process( \$template, { text => $text }, \$output );
    is( $output, $expected, 'Already has "target" attribute' );
}

###############################################################################
# Explicit "target"
explicit_target: {
    my $tt = Template->new();
    my $template = qq{[% USE LinkTarget(target="_top") %][%- text | linktarget -%]};
    my $text     = qq{<a href="_href">foo</a>};
    my $expected = qq{<a href="_href" target="_top">foo</a>};
    my $output;
    $tt->process( \$template, { text => $text }, \$output );
    is( $output, $expected, 'Explicit "target" attribute' );
}

###############################################################################
# Exclude URLs from having a "target" assigned to them; single URL
exclude_url_single: {
    my $tt = Template->new();
    my $template = qq{
[%- USE LinkTarget(exclude='www.example.com') -%]
[% FILTER linktarget %]
<a href="http://www.example.com/">example</a>
<a href="http://www.google.com/">google</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">example</a>
<a href="http://www.google.com/" target="_blank">google</a>
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'exclude single URL' );
}

###############################################################################
# Exclude URLs from having a "target" assigned to them; multiple URLs
exclude_url_multiple: {
    my $tt = Template->new();
    my $template = qq{
[%- USE LinkTarget(exclude=['www.example.com','www.foobar.com']) -%]
[% FILTER linktarget %]
<a href="http://www.example.com/">example</a>
<a href="http://www.google.com/">google</a>
<a href="http://www.foobar.com/">foobar</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">example</a>
<a href="http://www.google.com/" target="_blank">google</a>
<a href="http://www.foobar.com/">foobar</a>
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'exclude multiple URLs' );
}

###############################################################################
# Exclude URLs from having a "target" assigned to them; regexes
exclude_url_regex: {
    my $tt = Template->new();
    my $template = qq{
[%- USE LinkTarget(exclude=['^http://(?:\\w+\\.)*example.com']) -%]
[% FILTER linktarget %]
<a href="http://www.example.com/">example</a>
<a href="http://example.com/">example</a>
<a href="ftp://www.example.com/">FTP</a>
<a href="http://www.google.com/">google</a>
[%- END %]
};
    my $expected = qq{
<a href="http://www.example.com/">example</a>
<a href="http://example.com/">example</a>
<a href="ftp://www.example.com/" target="_blank">FTP</a>
<a href="http://www.google.com/" target="_blank">google</a>
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'exclude regex' );
}

###############################################################################
# Make sure that HTML entities encoded in attributes get reformed properly.
html_entity_attribute_reforming: {
    my $tt = Template->new();
    my $template = qq{[% USE LinkTarget %][%- text | linktarget -%]};
    my $text     = qq{<a rel="next =&gt;" href="_href">foo</a>};
    my $expected = qq{<a rel="next =&gt;" href="_href" target="_blank">foo</a>};
    my $output;
    $tt->process( \$template, { text => $text }, \$output );
    is( $output, $expected, 'HTML entities in existing attributes' );
}
