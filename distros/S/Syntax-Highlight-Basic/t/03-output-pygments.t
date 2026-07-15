#!perl
use 5.016;
use strict;
use warnings;

use Test::More;

use lib 'lib';
use Syntax::Highlight::Basic::Output::Pygments;

#===========================================================================
# Output::Pygments Tests
#===========================================================================

#===========================================================================
# Constructor
#===========================================================================

{
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    isa_ok($o, 'Syntax::Highlight::Basic::Output::Pygments', 'constructor succeeds');
}

#===========================================================================
# Basic conversion
#===========================================================================

{
    my $tokens = [
        [
            { class => 'Statement', sub_group => 'Keyword', text => 'if' },
            { class => 'whitespace', sub_group => undef, text => ' ' },
            { class => 'Special', sub_group => 'Delimiter', text => '(' },
        ]
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    like($html, qr/<span class="k">if<\/span>/, 'keyword gets class="k"');
    like($html, qr/ /, 'whitespace appears as-is');
    like($html, qr/<span class="p">\(<\/span>/, 'delimiter gets class="p"');
}

#===========================================================================
# HTML escaping
#===========================================================================

{
    my $tokens = [
        [
            { class => 'Special', sub_group => undef, text => chr(60) . 'script' . chr(62) },
        ]
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    my $lt_ent  = chr(38) . 'lt;';
    my $gt_ent  = chr(38) . 'gt;';
    like($html, qr/\Q$lt_ent\Escript\Q$gt_ent\E/, '<script> is HTML-escaped');
}

{
    my $tokens = [
        [
            { class => 'Constant', sub_group => 'String', text => chr(34) . 'quoted' . chr(34) },
        ]
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    my $quot_ent = chr(38) . 'quot;';
    like($html, qr/\Q$quot_ent\Equoted\Q$quot_ent\E/, '"quoted" is HTML-escaped');
}

{
    my $tokens = [
        [
            { class => 'Special', sub_group => undef, text => chr(38) },
        ]
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    my $amp_ent = chr(38) . 'amp;';
    like($html, qr/\Q$amp_ent\E/, '& is escaped to &');
}

#===========================================================================
# Multi-line output
#===========================================================================

{
    my $tokens = [
        [{ class => 'text', sub_group => undef, text => 'line1' }],
        [{ class => 'text', sub_group => undef, text => 'line2' }],
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    like($html, qr/\n/, 'multi-line output contains newline');
}

#===========================================================================
# wrap => 1
#===========================================================================

{
    my $tokens = [
        [{ class => 'text', sub_group => undef, text => 'code' }],
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new(wrap => 1);
    my $html = $o->convert($tokens);

    like($html, qr/^<div class="highlight">/, 'wrap starts with div.highlight');
    like($html, qr/<\/div>$/, 'wrap ends with </div>');
}

#===========================================================================
# Unknown group
#===========================================================================

{
    my $tokens = [
        [
            { class => 'UnknownGroup', sub_group => undef, text => 'blah' },
        ]
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new();
    my $html = $o->convert($tokens);

    unlike($html, qr/<span/, 'unknown group has no span');
    like($html, qr/blah/, 'unknown group text appears as-is');
}

#===========================================================================
# css_class option
#===========================================================================

{
    my $tokens = [
        [{ class => 'text', sub_group => undef, text => 'code' }],
    ];
    my $o = Syntax::Highlight::Basic::Output::Pygments->new(wrap => 1, css_class => 'my-hl');
    my $html = $o->convert($tokens);

    like($html, qr/class="my-hl"/, 'custom css_class is used');
}

done_testing();