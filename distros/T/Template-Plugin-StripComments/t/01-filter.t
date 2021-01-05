use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Template;
use Test::More tests => 7;

my $text     = '/* remove */<!-- remove -->foo';
my $expected = 'foo';

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
# C-style comment removal.
c_style_comments: {
    my $tt = Template->new();
    my $template = qq{
[%- USE StripComments -%]
[%- FILTER stripcomments -%]
/* single line comment */
/* multi
 * line
 * comment
 */
foo
[%- END -%]
};
    my $expected = qq{\n\nfoo};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Strip C-style comments' );
}

###############################################################################
# HTML comment removal.
html_style_comments: {
    my $tt = Template->new();
    my $template = qq{
[%- USE StripComments -%]
[%- FILTER stripcomments -%]
<!-- single line comment -->
<!-- multi
     line
     comment -->
foo
[%- END -%]
};
    my $expected = qq{\n\nfoo};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Strip HTML comments' );
}

###############################################################################
# Use as a FILTER
filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE StripComments -%]
[%- FILTER stripcomments -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Works in [% FILTER .. %] block' );
}

###############################################################################
# Use as named FILTER
named_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE foo = StripComments -%]
[%- FILTER \$foo -%]
$text
[%- END -%]
};
    my $output;
    $tt->process( \$template, undef, \$output );
    is( $output, $expected, 'Works in named [% FILTER .. %] block' );
}

###############################################################################
# Use as inline filter
inline_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE StripComments -%]
[%- text | stripcomments -%]
};
    my $output;
    $tt->process( \$template, { 'text' => $text }, \$output );
    is( $output, $expected, 'Works as inline filter' );
}

###############################################################################
# Use as named inline filter.
named_inline_filter: {
    my $tt = Template->new();
    my $template = qq{
[%- USE foo = StripComments -%]
[%- text | \$foo -%]
};
    my $output;
    $tt->process( \$template, { 'text' => $text }, \$output );
    is( $output, $expected, 'Works as named inline filter' );
}
