use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 4;

template 'index.html' => sub {
    html {
        head {};
        body {
            show 'my/content';
            }
        }

};

template 'dash-test' => sub {
    html {
        head {};
        body {
            show 'my/content';
            }
        }

};


template 'my/content' => sub {
        div { attr { id => 'body' }
            outs('This is my content')
        }

};


require "t/utils.pl";

Template::Declare->init(dispatch_to => ['Wifty::UI']);




for('index.html', 'dash-test'){ 
{
Template::Declare->buffer->clear;
my $simple =(show($_));
ok($simple =~ 'This is my content');
#diag ($simple);
ok_lint($simple);
}
}


1;
