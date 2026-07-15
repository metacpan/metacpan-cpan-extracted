#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic;

#===========================================================================
# Integration Tests — facade module end-to-end
#===========================================================================

#===========================================================================
# Pygments format
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('if ($x) {}', 'perl', { format => 'pygments' });
    like($result, qr/<span class="k">if<\/span>/, 'pygments: if gets class="k"');
}

#===========================================================================
# HTML format
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('if ($x) {}', 'perl', { format => 'html' });
    like($result, qr/<span style=/, 'html: output contains span with style');
}

#===========================================================================
# ANSI format
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('if ($x) {}', 'perl', { format => 'ansi' });
    my $esc = chr(27);
    like($result, qr/\Q${esc}[0m\E/, 'ansi: output contains ANSI reset code');
}

#===========================================================================
# Fallback language
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('"hello"', undef, { format => 'pygments' });
    like($result, qr/<span class="s">/, 'fallback: string gets class="s"');
}

#===========================================================================
# wrap option
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('code', 'perl', { format => 'pygments', wrap => 1 });
    like($result, qr/^<div class="highlight">/, 'wrap: starts with div.highlight');
}

#===========================================================================
# Default format is html
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('if', 'perl');
    like($result, qr/<span style=/, 'default format produces HTML with style');
}

#===========================================================================
# css_class option
#===========================================================================

{
    my $shb = Syntax::Highlight::Basic->new();
    my $result = $shb->highlight('code', 'perl', {
        format    => 'pygments',
        wrap      => 1,
        css_class => 'custom-hl',
    });
    like($result, qr/class="custom-hl"/, 'css_class is passed through');
}

done_testing();