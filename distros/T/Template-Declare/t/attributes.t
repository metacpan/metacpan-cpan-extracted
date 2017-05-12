
use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

# call to attr with emplecit ';'
template attr_with_one_arg => sub {
    div { attr { id => 'id' };
        p { 'This is my content' }
    }
};

template attr_with_two_args => sub {
    div { attr { id => 'id' }
        p { 'This is my content' }
    }
};

template attr_with_many_args => sub {
    div { attr { id => 'id' }
        p { 'This is my content' }
        p { 'another paragraph' }
        p { 'another paragraph' }
        p { 'another paragraph' }
    }
};

template with => sub {
    with( id => 'id' ),
    div { p { 'This is my content' } }
};

template with_with_two_blocks => sub {
    with( id => 'id' ),
    div { p { 'This is my content' } }
    div { p { 'another paragraph' } }
};

Template::Declare->init(dispatch_to => ['Wifty::UI']);

1;

use Test::More tests => 10;
require "t/utils.pl";
{
    my $simple = (show_page('attr_with_one_arg'));
    ok($simple =~ m{^\s*<div\s+id="id">\s*<p>\s*This is my content\s*</p>\s*</div>\s*$}s);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show_page('attr_with_two_args'));
    ok($simple =~ m{^\s*<div\s+id="id">\s*<p>\s*This is my content\s*</p>\s*</div>\s*$}s);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show_page('attr_with_many_args'));
    ok($simple =~ m{^\s*
        <div\s+id="id">\s*
        <p>\s*This\sis\smy\scontent\s*</p>\s*
        (<p>\s*another\sparagraph\s*</p>\s*)+
        </div>\s*
    $}sx);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show_page('with'));
    ok($simple =~ m{^\s*<div\s+id="id">\s*<p>\s*This is my content\s*</p>\s*</div>\s*$}s);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

{
    my $simple = (show_page('with_with_two_blocks'));
    ok($simple =~ m{^\s*
        <div\s+id="id">\s*<p>\s*This\sis\smy\scontent\s*</p>\s*</div>\s*
        <div>\s*<p>\s*another\sparagraph\s*</p>\s*</div>\s*
    $}sx);
    #diag ($simple);
    ok_lint($simple);
}
Template::Declare->buffer->clear;

