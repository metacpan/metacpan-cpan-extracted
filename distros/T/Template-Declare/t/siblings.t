use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 7;
require "t/utils.pl";

template tag_tag => sub {
    head { }
    body { }
};

template tag_show => sub {
    h1 { 'heading' }
    show('tag_tag')
};

template tag_text => sub {
    h1 { }
    'text'
};


Template::Declare->init(dispatch_to => ['Wifty::UI']);


{
    Template::Declare->buffer->clear;
    my $simple =(show('tag_tag'));
    like($simple, qr/head.*body/ms, 'body after head');
    ok_lint($simple);
}

{
    Template::Declare->buffer->clear;
    my $simple =(show('tag_show'));
    TODO: {
        local $TODO = 'fixme';
        like($simple, qr/\A\s*<h1/ms, 'show() after tag');
    }
    ok_lint($simple);
}

{
    Template::Declare->buffer->clear;
    my $simple =(show('tag_text'));
    like($simple, qr/\A\s*<h1/ms, 'tag is leading');
    TODO: {
        local $TODO = 'fixme';
        like($simple, qr/text/ms, 'text in the result');
    }
    ok_lint($simple);
}

1;
