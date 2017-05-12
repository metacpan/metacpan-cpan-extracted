use strict;
use warnings;
use utf8;
use Test::More;
use Template;
use Encode;

# 鬱膣愛味噌

my @tests = (
    +{
        input => {
            template =>
            "[% USE MobileJPPictogram %][% x | pictogram_charname('***%s***') %]",
            x        => 'PICT:\x{E754}',
        },
        expected => 'PICT:***ウマ***'
    },
    {
        input => {
            template => q{[% USE MobileJPPictogram %][% x | pictogram_unicode('<img src="/img/pictogram/%04X.gif" />') %]},
            x        => q!PICT:\x{E754}!,
        },
        expected => q{PICT:<img src="/img/pictogram/E754.gif" />},
    },
    {
        input => {
            template => q{[% USE MobileJPPictogram %][% x | pictogram_unicode('<img src="/img/pictogram/%d.gif" />') %]},
            x        => q!PICT:\x{E754}!,
        },
        expected => q{PICT:<img src="/img/pictogram/59220.gif" />},
    },
);

plan tests => 0+@tests;
for my $t (@tests) {
    is(escape($t->{input}), $t->{expected}, $t->{expected});
}

sub decode_uni {
    local $_ = shift;
    s/\\x\{(....)\}/pack "U*", hex $1/ge;
    $_;
}

sub escape {
    my $in = shift;
    my $tt = Template->new;
    $tt->process(\$in->{template}, {x => decode_uni($in->{x})}, \my $out) or die $tt->error;
    $out;
}


