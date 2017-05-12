use warnings;
use strict;
use utf8;# 'UTF-8';


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

# 'test' in Russian
my $str = "\x{442}\x{435}\x{441}\x{442}";

template simple_outs => sub { outs("$str") };
template double_outs => sub { outs("$str"); outs("$str") };

template tag_outs => sub { p { outs("$str") } };
template double_tag_outs => sub { p { outs("$str") } p { outs("$str") } };

template attr => sub { p {{ title is "$str" }} };
template attr_with_escape => sub { p {{ title is "<$str>" }} };


Template::Declare->init(dispatch_to => ['Wifty::UI']);

1;

use Test::More tests => 12;
require "t/utils.pl";

{
    my $simple = (show('simple_outs'));
    ok($simple =~ m{^\s*$str\s*$}s);
    # diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show('double_outs'));
    ok($simple =~ m{^\s*$str\s*$str\s*$}s);
    # diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show('tag_outs'));
    ok($simple =~ m{^\s*<p>\s*$str\s*</p>\s*$}s);
    ok_lint($simple, 1);
}
Template::Declare->buffer->clear;

{
    my $simple = (show('double_tag_outs'));
    ok($simple =~ m{^\s*<p>\s*$str\s*</p>\s*<p>\s*$str\s*</p>\s*$}s);
    ok_lint($simple, 1);
}
Template::Declare->buffer->clear;

{
    my $simple = (show('attr'));
    ok($simple =~ m{^\s*<p\s+title="$str"\s*></p>\s*$}s);
    # diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show('attr_with_escape'));
    ok($simple =~ m{^\s*<p\s+title="&lt;$str&gt;"\s*></p>\s*$}s);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

