use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests =>2 ;

template simple => sub {

html { 
    head { }
        body {
            form { attr { target => '/page.html', method => 'POST' };
                    input { 
                            attr{ type => 'text'} };
            }
        }
}

};

package Template::Declare::Tags;
require "t/utils.pl";
use Test::More;

our $self;
local $self = {};
bless $self, 'Wifty::UI';

Template::Declare->init( dispatch_to => ['Wifty::UI']);

{
Template::Declare->buffer->clear;
my $simple =(show('simple'));
ok($simple =~ '<form', "we have a form");
#diag ($simple);
ok_lint($simple);
}


1;
