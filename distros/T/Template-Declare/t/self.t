use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {
    my $self = shift;
    html {
        head {};
        body { outs( 'This is my content from' . $self ); };
        }

};

private template 'private-content' => sub {
    with( id => 'body' ), div {
        outs('This is my content from'.$self);
    };
};

package main;
Template::Declare->init(dispatch_to => ['Wifty::UI']);

use Test::More tests => 3;
require "t/utils.pl";
{
    local $Template::Declare::Tags::self = 'Wifty::UI';
    my $simple =  Template::Declare::Tags::show('simple') ;
    like( $simple,  qr'This is my content' );
    like( $simple,  qr'Wifty::UI', '$self is correct in template block' );
    ok_lint($simple);
}


1;
