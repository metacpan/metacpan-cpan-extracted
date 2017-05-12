use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 2;
require "t/utils.pl";

template a_tag => sub { em {} };

template show => sub { show 'a_tag' };

template show_in_tag => sub { div { show 'a_tag' } };

Template::Declare->init(dispatch_to => ['Wifty::UI']);

{
    Template::Declare->buffer->clear;
    my $simple =(show('show'));
    like($simple, qr{^\s*<em>\s*</em>\s*$}ms, 'show => sub { div { show a_tag } }');
}

{
    Template::Declare->buffer->clear;
    my $simple =(show('show_in_tag'));
    like($simple, qr{^\s*<div>\s*<em>\s*</em>\s*</div>\s*$}ms, 'show => sub { div { show a_tag } }');
}

1;
