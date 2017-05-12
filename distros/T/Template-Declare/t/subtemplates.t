use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 9;
require "t/utils.pl";

template simple => sub {

html { 
    head { };
        body { show 'my/content' }
}

};

template toplevel => sub {
    html { head {};
        body  { show 'content' }
        };
};


template 'my/content' => sub {
        div { attr { id => 'body' };
            p {'This is my content'}
        }
};


template 'my/wrapper' => sub {
    show './content';

};

template  'content' => sub { 
    p { 'TOPLEVEL CONTENT'};
};


Template::Declare->init(dispatch_to => ['Wifty::UI']);


{
Template::Declare->buffer->clear;
my $simple =(show('my/content'));
ok($simple =~ 'This is my content');
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
my $simple =(show('simple'));
ok($simple =~ 'This is my content');
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
my $simple = (show('toplevel'));
#diag $simple;
ok ($simple =~ /TOPLEVEL/, "CAlling /toplevel does call /content");
ok_lint($simple);
}

{
Template::Declare->buffer->clear;
my $simple = (show('my/wrapper'));
ok ($simple !~ /TOPLEVEL/, " Calling my/wrapper doesn't call /content" );
ok ($simple =~/my content/, "calling my/wrapper does call my/content");
ok_lint($simple);
}





1;
